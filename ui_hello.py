import re

import bpy

_selection_order_names: list[str] = []


def _track_selection_order(_scene, _depsgraph):
    current_names = [obj.name for obj in bpy.context.selected_objects]

    # Keep only still selected names.
    _selection_order_names[:] = [
        name for name in _selection_order_names if name in current_names
    ]

    # Append newly selected objects at the end.
    for name in current_names:
        if name not in _selection_order_names:
            _selection_order_names.append(name)


def get_selection_ordered_objects(context):
    objects = []
    for name in _selection_order_names:
        obj = context.scene.objects.get(name)
        if obj is not None and obj.select_get():
            objects.append(obj)
    return objects


def rename_objects(objects: list[bpy.types.Object]):
    counter = 1
    for obj in objects:
        obj.name = f"{counter:03d}_$#{obj.name}"
        counter += 1


def remove_prefix_by_tokens(name: str) -> str:
    parts = [part for part in re.split(r"[_$#]+", name) if part]
    if len(parts) <= 1:
        return name
    return "_".join(parts[1:])


class ORDEROBJECTS_OT_show_start_text(bpy.types.Operator):
    bl_idname = "order_objects.show_start_text"
    bl_label = "Sortuj"
    bl_description = "Sortuje obiekty w kolejności zaznaczania"

    def _draw_popup(self, menu, context):
        selected_obj = context.selected_objects
        rename_objects(selected_obj)
        _selection_order_names.clear()
        for obj in selected_obj:
            obj.select_set(False)
        context.view_layer.objects.active = None
        menu.layout.label(
            text=(
                "Dodano perfixy do nazw zaznaczonych obiektow, "
                "dzieki czemu ukladaja sie one w kolejnosci zaznaczania"
            ),
            icon="INFO",
        )

    def execute(self, context):
        context.window_manager.popup_menu(
            self._draw_popup,
            title="Order Objects",
            icon="INFO",
        )
        return {"FINISHED"}


class ORDEROBJECTS_OT_clear_prefixes(bpy.types.Operator):
    bl_idname = "order_objects.clear_prefixes"
    bl_label = "Wyczysc prefiksy"
    bl_description = (
        "Usuwa prefiks z nazwy po podziale po _, $, # "
        "dla obiektow z aktywnej warstwy"
    )

    def execute(self, context):
        renamed_count = 0
        for obj in context.view_layer.objects:
            new_name = remove_prefix_by_tokens(obj.name)
            if new_name != obj.name:
                obj.name = new_name
                renamed_count += 1

        self.report(
            {"INFO"},
            ("Wyczyszczono prefiksy w " f"{renamed_count} obiektach aktywnej warstwy."),
        )
        return {"FINISHED"}


class ORDEROBJECTS_PT_main_panel(bpy.types.Panel):
    bl_label = "Order Objects"
    bl_idname = "ORDEROBJECTS_PT_main_panel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Order Objects"

    def draw(self, context):
        layout = self.layout
        col = layout.column(align=True)
        col.label(text="Zaznacz obiekty i sortuj")

        action_col = layout.column(align=True)
        action_col.operator("order_objects.show_start_text", icon="INFO")

        layout.separator(factor=0.5)

        clear_col = layout.column(align=True)
        clear_col.operator("order_objects.clear_prefixes", icon="TRASH")

        layout.separator()
        layout.label(text="Selected (kolejnosc zaznaczania):")

        ordered = get_selection_ordered_objects(context)
        if not ordered:
            layout.label(text="Brak zaznaczonych obiektow", icon="INFO")
            return

        for index, obj in enumerate(ordered, start=1):
            layout.label(text=f"{index}. {obj.name}", icon="OBJECT_DATA")


def register():
    if _track_selection_order not in bpy.app.handlers.depsgraph_update_post:
        bpy.app.handlers.depsgraph_update_post.append(_track_selection_order)


def unregister():
    if _track_selection_order in bpy.app.handlers.depsgraph_update_post:
        bpy.app.handlers.depsgraph_update_post.remove(_track_selection_order)

    _selection_order_names.clear()
