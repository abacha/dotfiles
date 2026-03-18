import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "../..")))
from myfitnesspal.parser import parse_public_diary_macros


def test_parse_public_diary_macros_success():
    html = """
    <html><body>
        <tr class="total">
            <td>Totals</td><td>100</td><td>50</td><td>20</td>
        </tr>
    </body></html>
    """
    res = parse_public_diary_macros(html)
    assert res["status"] == "success"
    assert res["macros"] == [["Totals", "100", "50", "20"]]


def test_parse_public_diary_macros_blocked():
    html = "<html><body>Blocked by Cloudflare</body></html>"
    res = parse_public_diary_macros(html)
    assert res["status"] == "blocked"


def test_parse_public_diary_macros_private():
    html = "<html><body>This diary is Private</body></html>"
    res = parse_public_diary_macros(html)
    assert res["status"] == "private"
