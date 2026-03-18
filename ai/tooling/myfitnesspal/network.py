import cloudscraper


def fetch_public_diary_html(username, target_date_str):
    url = f"https://www.myfitnesspal.com/food/diary/{username}?date={target_date_str}"
    scraper = cloudscraper.create_scraper(
        browser={"browser": "chrome", "platform": "windows", "desktop": True}
    )
    response = scraper.get(url)
    return response.status_code, response.text
