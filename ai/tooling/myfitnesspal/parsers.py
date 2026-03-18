import re
import xml.etree.ElementTree as ET
from typing import Any, Dict, Iterable, List, Optional, Tuple

from bs4 import BeautifulSoup

from .adb import MFP_PACKAGE, adb_find_node, adb_find_nodes

MEAL_ALIASES = {
    "pre_workout": "Pré-treino",
    "breakfast": "Café da manhã",
    "morning_snack": "Lanche da manhã",
    "lunch": "Almoço",
    "afternoon_snack": "Lanche da tarde",
    "dinner": "Jantar",
    "evening_snack": "Ceia",
    "snack": "Lanche",
    "exercise": "Exercício",
    "pre treino": "Pré-treino",
    "pré-treino": "Pré-treino",
    "cafe": "Café da manhã",
    "café": "Café da manhã",
    "cafe da manha": "Café da manhã",
    "café da manhã": "Café da manhã",
    "cafedamanha": "Café da manhã",
    "lanche da manha": "Lanche da manhã",
    "lanche da manhã": "Lanche da manhã",
    "almoco": "Almoço",
    "almoço": "Almoço",
    "lanche da tarde": "Lanche da tarde",
    "jantar": "Jantar",
    "ceia": "Ceia",
    "lanche": "Lanche",
    "exercicio": "Exercício",
}
SEARCH_RESULT_PRIMARY_IDS = [
    f"{MFP_PACKAGE}:id/text_primary",
    f"{MFP_PACKAGE}:id/txtItemDescription",
]
SEARCH_RESULT_SECONDARY_IDS = [
    f"{MFP_PACKAGE}:id/text_secondary",
    f"{MFP_PACKAGE}:id/txtItemDetails",
]


def node_text(node: Optional[ET.Element]) -> str:
    if node is None:
        return ""
    return node.attrib.get("text", "").strip()


def has_resource_id(root: Optional[ET.Element], resource_id: str) -> bool:
    return adb_find_node(root, resource_id=resource_id) is not None


def detect_screen(root: Optional[ET.Element]) -> str:
    if root is None:
        return "unknown"
    if has_resource_id(root, f"{MFP_PACKAGE}:id/onlineFoodSearchRecyclerView"):
        return "search_results"
    if has_resource_id(root, f"{MFP_PACKAGE}:id/searchEditText"):
        return "search"
    if (
        has_resource_id(root, f"{MFP_PACKAGE}:id/menu_action_item")
        or has_resource_id(root, f"{MFP_PACKAGE}:id/textMeal")
        or adb_find_node(root, text_exact="Adicionar alimento") is not None
    ):
        return "search"
    if has_resource_id(root, f"{MFP_PACKAGE}:id/txtSectionHeader") or has_resource_id(
        root, f"{MFP_PACKAGE}:id/btnComplete"
    ):
        return "diary"
    if (
        has_resource_id(root, "layoutCaloriesCard")
        or adb_find_node(root, text_exact="Painel") is not None
    ):
        return "home"
    return "unknown"


def split_calories_from_details(value: str) -> Tuple[str, str]:
    text = value.strip()
    if not text:
        return "", ""
    match = re.match(
        r"^(\d+(?:[.,]\d+)?)\s*cal(?:ories)?\s*,?\s*(.*)$", text, flags=re.IGNORECASE
    )
    if not match:
        return "", text
    calories = match.group(1).replace(",", ".")
    if calories.endswith(".0"):
        calories = calories[:-2]
    return f"{calories} cal", match.group(2).strip(" ,")


def simplify_text(value: str) -> str:
    return re.sub(
        r"\s+",
        " ",
        value.strip()
        .lower()
        .replace("ç", "c")
        .replace("ã", "a")
        .replace("á", "a")
        .replace("â", "a")
        .replace("é", "e")
        .replace("ê", "e")
        .replace("í", "i")
        .replace("ó", "o")
        .replace("ô", "o")
        .replace("õ", "o")
        .replace("ú", "u"),
    )


def normalize_meal_name(
    meal: Optional[str], available_meals: Optional[Iterable[str]] = None
) -> str:
    if not meal:
        return "Jantar"
    canonical = MEAL_ALIASES.get(meal.strip().lower(), meal.strip())
    if available_meals:
        normalized_available = {simplify_text(item): item for item in available_meals}
        return normalized_available.get(simplify_text(canonical), canonical)
    return canonical


def extract_meal_names(root: Optional[ET.Element]) -> List[str]:
    names = []
    for node in adb_find_nodes(root, resource_id=f"{MFP_PACKAGE}:id/txtSectionHeader"):
        text = node.attrib.get("text", "").strip()
        if text:
            names.append(text)
    return names


def extract_search_results(
    root: Optional[ET.Element], limit: int = 5
) -> List[Dict[str, Any]]:
    if root is None:
        return []
    results: List[Dict[str, Any]] = []
    seen = set()
    secondary_nodes = [
        node
        for node in root.iter("node")
        if node.attrib.get("resource-id", "") in SEARCH_RESULT_SECONDARY_IDS
    ]
    calorie_nodes = [
        node
        for node in root.iter("node")
        if node.attrib.get("resource-id", "") == f"{MFP_PACKAGE}:id/txtCalories"
    ]
    for primary_id in SEARCH_RESULT_PRIMARY_IDS:
        for idx, node in enumerate(adb_find_nodes(root, resource_id=primary_id)):
            name = node.attrib.get("text", "").strip()
            if not name or name in seen:
                continue
            secondary = (
                node_text(secondary_nodes[idx]) if idx < len(secondary_nodes) else ""
            )
            calories = node_text(calorie_nodes[idx]) if idx < len(calorie_nodes) else ""
            parsed_calories, parsed_details = split_calories_from_details(secondary)
            if parsed_calories and not calories:
                calories = parsed_calories
                secondary = parsed_details
            seen.add(name)
            results.append(
                {
                    "name": name,
                    "details": secondary,
                    "calories": calories,
                    "resource_id": primary_id,
                }
            )
            if len(results) >= limit:
                return results
    return results


def parse_weight_to_servings(weight_str: str, serving_text: str = "") -> float:
    weight_num = float(re.sub(r"[^0-9.]", "", weight_str.replace(",", ".")))
    multiplier = weight_num
    if serving_text:
        match = re.search(r"(\d+[.,]?\d*)", serving_text)
        if match:
            base_weight = float(match.group(1).replace(",", "."))
            if base_weight > 0:
                multiplier = weight_num / base_weight
    return multiplier


def parse_public_diary_macros(html):
    if "Blocked" in html:
        return {"status": "blocked", "macros": []}
    if "Private" in html or "password" in html.lower():
        return {"status": "private", "macros": []}

    soup = BeautifulSoup(html, "html.parser")
    totals = soup.find_all("tr", class_="total")
    macros = []
    if totals:
        for row in totals:
            cols = [td.get_text(strip=True) for td in row.find_all(["td", "th"])]
            if cols:
                macros.append(cols)
        return {"status": "success", "macros": macros}
    return {"status": "empty", "macros": []}
