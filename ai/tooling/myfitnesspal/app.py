import time
from typing import Any, Dict, List, Optional

from . import adb
from .parsers import (
    detect_screen,
    extract_meal_names,
    extract_search_results,
    node_text,
    normalize_meal_name,
    parse_weight_to_servings,
)


class MyFitnessPalApp:
    diary_tab_text = "Diário"
    diary_fallback_button_id = "buttonDiary"
    diary_section_header_id = f"{adb.MFP_PACKAGE}:id/txtSectionHeader"
    search_field_id = f"{adb.MFP_PACKAGE}:id/searchEditText"
    search_meal_selector_id = f"{adb.MFP_PACKAGE}:id/selectMeal"
    meal_option_id = f"{adb.MFP_PACKAGE}:id/mealName"
    result_primary_id = f"{adb.MFP_PACKAGE}:id/text_primary"
    result_fallback_id = f"{adb.MFP_PACKAGE}:id/txtItemDescription"
    result_quick_add_icon_id = f"{adb.MFP_PACKAGE}:id/quickLogAddRemoveIcon"
    serving_size_id = f"{adb.MFP_PACKAGE}:id/txtServingSize"
    quantity_ids = [
        f"{adb.MFP_PACKAGE}:id/txtNoOfServings",
        f"{adb.MFP_PACKAGE}:id/noOfServings",
    ]
    save_action_id = f"{adb.MFP_PACKAGE}:id/action_complete"

    def dump_ui(self):
        return adb.adb_dump()

    def dump_ui_raw(self, local_path: str):
        return adb.adb_dump_raw(local_path=local_path)

    def current_screen(self) -> str:
        return detect_screen(self.dump_ui())

    def is_locked(self) -> bool:
        return adb.is_device_locked()

    def open_app(self, force_restart: bool = False) -> None:
        adb.wake_unlock_device()
        adb.launch_app(force_restart=force_restart)

    def go_to_diary(self, force_restart: bool = False) -> None:
        self.open_app(force_restart=force_restart)
        diary = adb.wait_for_node(
            text_exact=self.diary_tab_text, timeout=12
        ) or adb.wait_for_node(resource_id=self.diary_fallback_button_id, timeout=2)
        if diary is not None:
            adb.adb_click(diary)
            adb.wait_for_screen(self.diary_section_header_id, timeout=4)
            return

        focus = adb.adb_exec(
            f"{adb.adb_prefix()} shell dumpsys window | grep mCurrentFocus"
        )
        if adb.MFP_PACKAGE in focus:
            self.back(times=2)
            diary_nav = adb.wait_for_node(
                resource_id=self.diary_fallback_button_id, timeout=3
            )
            if diary_nav is not None:
                adb.adb_click(diary_nav)
            else:
                adb.adb_tap(121, 2276)
            adb.wait_for_screen(self.diary_section_header_id, timeout=4)

    def back(self, times: int = 1):
        for _ in range(times):
            adb.adb_keyevent(4)

    def wait_for_search_field(self, timeout: int = 8):
        return adb.wait_for_node(resource_id=self.search_field_id, timeout=timeout)

    def open_food_search(self, meal: str) -> None:
        adb.adb_tap(537, 2278)
        time.sleep(2)
        adb.adb_tap(281, 1595)
        time.sleep(3)

        root = self.dump_ui()
        meal_selector = adb.adb_find_node(
            root, resource_id=self.search_meal_selector_id
        )
        if meal_selector is not None:
            adb.adb_click(meal_selector)
            time.sleep(2)
            option = adb.wait_for_node(
                text_exact=meal, resource_id=self.meal_option_id, timeout=8
            )
            if option is not None:
                adb.adb_click(option)
                time.sleep(2)

    def ensure_search_open(self, meal: str):
        search_bar = self.wait_for_search_field(timeout=3)
        if search_bar is None:
            self.open_food_search(meal)
            search_bar = self.wait_for_search_field(timeout=8)
        return search_bar

    def clear_search_field(self) -> None:
        adb.adb_keyevent(123)
        for _ in range(40):
            adb.adb_keyevent(67)

    def search_for(self, query: str, tab: str = "Todos") -> List[Dict[str, Any]]:
        search_bar = self.wait_for_search_field(timeout=8)
        if search_bar is None:
            return []
        adb.adb_click(search_bar)
        time.sleep(1)
        self.clear_search_field()
        adb.adb_text(query)
        time.sleep(1)
        adb.adb_keyevent(66)
        time.sleep(3)
        if tab != "Todos":
            self.select_search_tab(tab)
        return extract_search_results(self.dump_ui())

    def select_search_tab(self, tab_text: str) -> None:
        root = self.dump_ui()
        tab = adb.adb_find_node(root, text_exact=tab_text) or adb.adb_find_node(
            root, text_contains=tab_text
        )
        if tab is not None:
            adb.adb_click(tab)
            time.sleep(3)

    def available_meals(self) -> List[str]:
        return extract_meal_names(self.dump_ui())

    def resolve_meal_name(self, requested_meal: Optional[str]) -> str:
        return normalize_meal_name(requested_meal, self.available_meals())

    def quick_add(self, index: int) -> bool:
        plus_icons = adb.adb_find_nodes(
            self.dump_ui(), resource_id=self.result_quick_add_icon_id
        )
        if plus_icons and index <= len(plus_icons):
            adb.adb_click(plus_icons[index - 1])
            time.sleep(3)
            return True
        return False

    def open_result_details(self, index: int) -> bool:
        root = self.dump_ui()
        items = adb.adb_find_nodes(
            root, resource_id=self.result_primary_id
        ) or adb.adb_find_nodes(root, resource_id=self.result_fallback_id)
        if not items or index > len(items):
            return False
        adb.adb_click(items[index - 1])
        time.sleep(3)
        return True

    def detailed_add(self, index: int, qty: str) -> bool:
        if not self.open_result_details(index):
            return False
        self.set_serving_quantity(qty)
        return self.finish_add_flow()

    def set_serving_quantity(self, weight_str: str) -> None:
        root = self.dump_ui()
        portion_size = adb.adb_find_node(root, resource_id=self.serving_size_id)
        serving_text = (
            portion_size.attrib.get("text", "") if portion_size is not None else ""
        )
        multiplier = parse_weight_to_servings(weight_str, serving_text)

        if portion_size is not None:
            adb.adb_click(portion_size)
            time.sleep(1)
            one_gram = adb.wait_for_node(text_contains="1,0 grama", timeout=3)
            if one_gram is not None:
                adb.adb_click(one_gram)
                time.sleep(1)
                multiplier = parse_weight_to_servings(weight_str, "1")
            else:
                adb.adb_keyevent(4)
                time.sleep(1)

        root = self.dump_ui()
        qty_node = None
        for resource_id in self.quantity_ids:
            qty_node = adb.adb_find_node(root, resource_id=resource_id)
            if qty_node is not None:
                break
        if qty_node is None:
            return
        adb.adb_click(qty_node)
        edit = adb.wait_for_node(class_name="android.widget.EditText", timeout=4)
        if edit is None:
            return
        adb.adb_click(edit)
        for _ in range(8):
            adb.adb_keyevent(67)
        adb.adb_text(str(round(multiplier, 2)).replace(".", ","))
        time.sleep(1)
        save = adb.adb_find_node(self.dump_ui(), text_exact="Salvar")
        if save is not None:
            adb.adb_click(save)
        time.sleep(1)

    def finish_add_flow(self) -> bool:
        check = adb.wait_for_node(resource_id=self.save_action_id, timeout=3)
        if check is not None:
            adb.adb_click(check)
            return True
        root = self.dump_ui()
        fallback_add = adb.adb_find_node(root, content_desc="Adicionar")
        if fallback_add is not None:
            adb.adb_click(fallback_add)
            return True
        fallback_save = adb.adb_find_node(root, text_exact="Salvar")
        if fallback_save is not None:
            adb.adb_click(fallback_save)
            return True
        return False

    def prepare_to_add_from_pending(self, meal_name: str) -> None:
        self.open_app(force_restart=True)
        time.sleep(5)
        self.go_to_diary(force_restart=False)
        self.ensure_search_open(meal_name)

    def search_results_screen_summary(self, limit: int = 5) -> Dict[str, Any]:
        root = self.dump_ui()
        return {
            "screen": detect_screen(root),
            "meals": extract_meal_names(root),
            "results": extract_search_results(root, limit=limit),
            "selected_meal": node_text(
                adb.adb_find_node(
                    root, resource_id=f"{adb.MFP_PACKAGE}:id/selectMealText"
                )
            ),
            "search_hint": node_text(
                adb.adb_find_node(root, resource_id=self.search_field_id)
            ),
        }
