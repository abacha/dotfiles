import datetime
from typing import Any, Dict, List, Optional

from . import adb
from .app import MyFitnessPalApp
from .parsers import (
    detect_screen,
    extract_meal_names,
    extract_search_results,
    node_text,
    normalize_meal_name,
)
from .state import (
    clear_pending_add,
    describe_pending_add,
    load_pending_add,
    save_pending_add,
)


class MyFitnessPalClient:
    def __init__(self, app: Optional[MyFitnessPalApp] = None):
        self.app = app or MyFitnessPalApp()

    def _print_summary(
        self,
        *,
        screen: str,
        relevant: List[str],
        warnings: Optional[List[str]] = None,
        next_actions: Optional[List[str]] = None,
        extra: Optional[List[str]] = None,
    ) -> None:
        print(f"screen: {screen}")
        print("relevant:")
        for item in relevant or ["none detected"]:
            print(item if item.startswith("- ") else f"- {item}")
        print("warnings:")
        for item in warnings or ["none"]:
            print(item if item.startswith("- ") else f"- {item}")
        print("next:")
        for item in next_actions or ["none"]:
            print(item if item.startswith("- ") else f"- {item}")
        for item in extra or []:
            print(item)

    def _screen_summary(self, root) -> Dict[str, Any]:
        screen = detect_screen(root)
        meals = extract_meal_names(root)
        search_results = (
            extract_search_results(root, limit=5) if screen == "search_results" else []
        )
        headings: List[str] = []
        for resource_id in [
            f"{adb.MFP_PACKAGE}:id/onlineSearchStatus",
            f"{adb.MFP_PACKAGE}:id/selectMealText",
            f"{adb.MFP_PACKAGE}:id/searchEditText",
        ]:
            text = node_text(adb.adb_find_node(root, resource_id=resource_id))
            if text and text not in headings:
                headings.append(text)

        relevant: List[str] = []
        selected_meal = node_text(
            adb.adb_find_node(root, resource_id=f"{adb.MFP_PACKAGE}:id/selectMealText")
        )
        search_hint = node_text(
            adb.adb_find_node(root, resource_id=f"{adb.MFP_PACKAGE}:id/searchEditText")
        )
        if meals:
            relevant.append(f"meals visible: {', '.join(meals[:5])}")
        if search_results:
            relevant.append(f"results visible: {len(search_results)}")
            relevant.append(f"top result: {search_results[0]['name']}")
        if selected_meal:
            relevant.append(f"selected meal: {selected_meal}")
        if search_hint:
            relevant.append(f"search field: {search_hint}")
        if headings:
            relevant.append(f"labels: {', '.join(headings[:3])}")
        if not relevant:
            clickable_count = len(
                [
                    n
                    for n in adb.adb_find_nodes(root)
                    if n.attrib.get("clickable") == "true"
                ]
            )
            relevant.append(f"clickable elements: {clickable_count}")

        return {
            "screen": screen,
            "meals": meals,
            "results": search_results,
            "relevant": relevant,
        }

    def launch(self) -> bool:
        self.app.go_to_diary()
        summary = self._screen_summary(adb.adb_dump())
        self._print_summary(
            screen=summary["screen"],
            relevant=summary["relevant"],
            warnings=[]
            if summary["screen"] == "diary"
            else ["app opened but diary screen was not guaranteed"],
            next_actions=["view-diary", "meals", "search-food --query '...'"],
        )
        return True

    def view_diary(self, target_date: datetime.date) -> bool:
        self.app.go_to_diary()
        summary = self._screen_summary(adb.adb_dump())
        self._print_summary(
            screen=summary["screen"],
            relevant=[f"requested date: {target_date:%Y-%m-%d}"] + summary["relevant"],
            warnings=["requested date not guaranteed; verify inside app"],
            next_actions=[
                "meals",
                "search-food --query '...'",
                "dump-ui --output /tmp/mfp_dump.xml",
            ],
        )
        return True

    def dump_ui(self, output_path: Optional[str] = None) -> bool:
        save_path = output_path or "/tmp/mfp_dump.xml"
        root, raw = self.app.dump_ui_raw(save_path)
        if root is None:
            self._print_summary(
                screen="unknown",
                relevant=[f"output path: {save_path}"],
                warnings=["ui dump failed"],
                next_actions=["retry dump-ui", "launch"],
            )
            return False
        summary = self._screen_summary(root)
        self._print_summary(
            screen=summary["screen"],
            relevant=[f"output path: {save_path}", f"xml chars: {len(raw)}"]
            + summary["relevant"],
            warnings=[],
            next_actions=["inspect saved xml", "status", "search-food --query '...'"],
        )
        return True

    def list_meals(self) -> List[str]:
        self.app.go_to_diary()
        summary = self._screen_summary(adb.adb_dump())
        meals = summary["meals"]
        relevant = (
            [f"meal sections: {', '.join(meals)}"]
            if meals
            else ["meal sections: none detected"]
        )
        if meals:
            relevant.append(f"sections with visible content: {len(meals)}")
        self._print_summary(
            screen=summary["screen"],
            relevant=relevant,
            warnings=[] if meals else ["no meal sections detected in current UI dump"],
            next_actions=["view-diary", "search-food --query '...'"],
        )
        return meals

    def status(self) -> Dict[str, Any]:
        info = describe_pending_add()
        relevant = [f"pending path: {info['path']}"]
        warnings: List[str] = []
        if info["exists"]:
            relevant.extend(
                [
                    f"pending query: {info.get('query')}",
                    f"pending meal: {info.get('meal')}",
                    f"pending weight: {info.get('weight') or 'unset'}",
                    f"pending results: {info.get('result_count')}",
                ]
            )
            next_actions = [
                "confirm-add --pick 1 --weight '...'",
                "cancel-add",
                "search-food --query '...' to replace pending state",
            ]
            if not info.get("result_count"):
                warnings.append("pending state has no confirmable results")
        else:
            relevant.append("pending add: none")
            next_actions = ["search-food --query '...'", "launch"]
        self._print_summary(
            screen="pending_state",
            relevant=relevant,
            warnings=warnings,
            next_actions=next_actions,
        )
        return info

    def cancel_add(self) -> bool:
        info_before = describe_pending_add()
        removed = clear_pending_add()
        relevant = [f"pending existed: {'yes' if info_before['exists'] else 'no'}"]
        if info_before["exists"]:
            relevant.append(f"cleared path: {info_before['path']}")
        self._print_summary(
            screen="pending_state",
            relevant=relevant,
            warnings=[]
            if removed or not info_before["exists"]
            else ["pending state could not be cleared"],
            next_actions=["search-food --query '...'", "status"],
            extra=[
                "result: pending state cleared"
                if removed
                else "result: nothing to clear"
            ],
        )
        return True

    def search_food(
        self,
        query: str,
        target_meal: str,
        weight_str: Optional[str] = None,
        limit: int = 5,
        tab: str = "all",
    ) -> List[Dict[str, Any]]:
        self.app.go_to_diary()
        meal_name = self.app.resolve_meal_name(target_meal)
        tab_mapping = {
            "all": "Todos",
            "meals": "Minhas Refeições",
            "recipes": "Minhas receitas",
            "foods": "Meus Alimentos",
        }
        tab_text = tab_mapping.get(tab, "Todos")

        search_bar = self.app.ensure_search_open(meal_name)
        if search_bar is None:
            raise RuntimeError(
                "Não foi possível abrir a tela de busca de alimentos com segurança."
            )

        results = self.app.search_for(query, tab=tab_text)[:limit]
        path = save_pending_add(
            {
                "query": query,
                "meal": meal_name,
                "weight": weight_str,
                "tab": tab_text,
                "date": datetime.date.today().isoformat(),
                "results": results,
                "suggested_index": 1 if results else None,
            }
        )

        relevant = [f"query: {query}", f"meal: {meal_name}", f"pending path: {path}"]
        if weight_str:
            relevant.append(f"requested weight: {weight_str}")
        warnings: List[str] = []
        extra: List[str] = []
        if not results:
            warnings.append("no results detected in current UI")
            extra.append("result: no food was added")
            self._print_summary(
                screen="search_results",
                relevant=relevant,
                warnings=warnings,
                next_actions=[
                    "search-food --query '...'",
                    "cancel-add",
                    "dump-ui --output /tmp/mfp_dump.xml",
                ],
                extra=extra,
            )
            return []

        relevant.append(f"results ranked: {len(results)}")
        for idx, item in enumerate(results, start=1):
            details = f" | {item['details']}" if item.get("details") else ""
            calories = f" | {item['calories']}" if item.get("calories") else ""
            marker = " | suggested" if idx == 1 else ""
            extra.append(f"rank {idx}: {item['name']}{details}{calories}{marker}")
        extra.append("result: no food was added")
        self._print_summary(
            screen="search_results",
            relevant=relevant,
            warnings=warnings,
            next_actions=[
                "confirm-add --pick 1 --weight '...'",
                "cancel-add",
                "search-food --query '...' to replace results",
            ],
            extra=extra,
        )
        return results

    def confirm_add(
        self,
        pick: int = 1,
        weight_str: Optional[str] = None,
        target_meal: Optional[str] = None,
        quick_add: bool = False,
    ) -> bool:
        pending = load_pending_add()
        if not pending:
            self._print_summary(
                screen="pending_state",
                relevant=["pending add: none"],
                warnings=["no pending search to confirm"],
                next_actions=["search-food --query '...'", "status"],
            )
            return False
        results = pending.get("results") or []
        if not results:
            self._print_summary(
                screen="pending_state",
                relevant=[
                    f"pending query: {pending.get('query')}",
                    "pending results: 0",
                ],
                warnings=["pending state exists but has no confirmable results"],
                next_actions=["search-food --query '...'", "cancel-add"],
            )
            return False
        if pick < 1 or pick > len(results):
            self._print_summary(
                screen="pending_state",
                relevant=[
                    f"pending results: {len(results)}",
                    f"requested pick: {pick}",
                ],
                warnings=[f"pick must be between 1 and {len(results)}"],
                next_actions=["confirm-add --pick 1 --weight '...'", "status"],
            )
            return False

        selected = results[pick - 1]
        meal_name = normalize_meal_name(target_meal or pending.get("meal"))
        effective_weight = weight_str or pending.get("weight")
        is_quick_add = quick_add or not effective_weight
        ok = self._add_food_via_adb(
            pending.get("query", ""),
            effective_weight or "quick_add",
            meal_name,
            tab_text=pending.get("tab", "Todos"),
            pick_index=pick,
            is_quick_add=is_quick_add,
        )
        relevant = [f"selected item: {selected['name']}", f"meal: {meal_name}"]
        if effective_weight:
            relevant.append(f"weight: {effective_weight}")
        if is_quick_add:
            relevant.append("mode: quick add (+ button)")
        if ok:
            clear_pending_add()
            self._print_summary(
                screen="confirm_add",
                relevant=relevant + ["controls found: enough to finish flow"],
                warnings=[],
                next_actions=["view-diary", "search-food --query '...'"],
                extra=["result: add flow completed"],
            )
            return True
        self._print_summary(
            screen="confirm_add",
            relevant=relevant + ["controls found: partial"],
            warnings=["could not complete add flow safely"],
            next_actions=["status", "cancel-add", "dump-ui --output /tmp/mfp_dump.xml"],
            extra=["result: add flow stopped before safe completion"],
        )
        return False

    def _add_food_via_adb(
        self,
        food_query: str,
        weight_str: str,
        target_meal: str = "dinner",
        tab_text: str = "Todos",
        pick_index: int = 1,
        is_quick_add: bool = False,
    ) -> bool:
        print("detail: ensure diary screen")
        self.app.prepare_to_add_from_pending(target_meal)
        print("detail: opening food search")
        print("detail: waiting for search bar")
        search_bar = self.app.wait_for_search_field(timeout=8)
        if search_bar is None:
            print("detail: missing search field")
            return False
        print("detail: clicking search bar")
        print(f"detail: typing {food_query}")
        self.app.search_for(food_query, tab=tab_text)
        print("detail: waiting for results")
        if is_quick_add:
            print("detail: clicking quick add icon")
            if self.app.quick_add(pick_index):
                print("detail: quick add completed")
                return True
            print("detail: quick add icon not found, falling back to detailed add")
        print(f"detail: clicking item at index {pick_index}")
        ok = self.app.detailed_add(pick_index, weight_str)
        if ok:
            print("detail: action_complete clicked")
            return True
        print("detail: no safe completion control found")
        return False


def get_client():
    return MyFitnessPalClient()
