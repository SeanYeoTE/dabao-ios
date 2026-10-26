#!/usr/bin/python3
"""Generates Dabao/Resources/restaurants.json: 100 fictional Singapore restaurants.

Python 3.9 standard library only. The output is deterministic (fixed seed, fixed order),
so running it twice gives byte-identical files:

    /usr/bin/python3 scripts/gen_catalogue.py
"""
import json
import os
import random

SEED = 20261026
OUTPUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "Dabao", "Resources", "restaurants.json")

CATEGORY_ORDER = ["Mains", "Noodles", "Rice", "Sets", "Sides", "Snacks", "Desserts", "Drinks"]

AREAS = [
    "Katong", "Tiong Bahru", "Geylang", "Bugis", "Jurong East", "Tampines", "Toa Payoh", "Bedok",
    "Woodlands", "Clementi", "Serangoon", "Chinatown", "Little India", "Holland Village", "Hougang",
    "Yishun", "Ang Mo Kio", "Queenstown", "Bishan", "Pasir Ris", "Kallang", "Novena", "Punggol",
    "Sengkang", "Bukit Timah", "Joo Chiat", "Telok Ayer", "Lavender", "Redhill", "Marine Parade",
]

# Curated brand-friendly tile colours.
PALETTE = {
    "pink": "#D70F64", "orange": "#E4572E", "amber": "#E8A317", "blue": "#2E86AB", "teal": "#17A398",
    "purple": "#6A4C93", "green": "#2A9D6F", "coral": "#E76F51", "navy": "#3D5A80", "violet": "#8338EC",
    "rose": "#EF476F", "olive": "#7A8B2E", "brown": "#8B5E3C", "red": "#C8312B",
}

# D = (name, description, category, low price, high price, spicy, tags)
def D(name, desc, cat, lo, hi, spicy=False, tags=()):
    return (name, desc, cat, lo, hi, spicy, list(tags))


CUISINES = {
    "Hawker": dict(
        count=15, symbols=["fork.knife", "fork.knife", "takeoutbag.and.cup.and.straw.fill"], colors=["orange", "red", "amber"],
        price=[1, 1, 1, 2], tags=["hawker", "local favourites", "halal-friendly", "wok hei"],
        suffix=["Hawker Stall", "Kitchen", "Food Stall", "Delights", "Famous Food"],
        blurbs=["A neighbourhood stall known for {sig}, served the way it was in the old hawker centres.",
                "Family-run for decades. Come for the {sig}, stay for the chilli.",
                "Wok-fired and made to order. The {sig} is the one regulars ask for."],
        mains=[
            D("Hokkien Mee", "Prawn stock noodles fried with squid, egg and crispy pork lard.", "Noodles", 5, 8, False, ["noodles", "prawn", "wok hei"]),
            D("Char Kway Teow", "Flat rice noodles wok-fried with cockles, lap cheong and egg.", "Noodles", 4.5, 7, True, ["noodles", "wok hei", "cockles"]),
            D("Bak Chor Mee", "Minced pork noodles tossed in vinegar and chilli.", "Noodles", 4.5, 7, True, ["noodles", "pork", "vinegar"]),
            D("Wanton Mee", "Springy noodles with char siu and fried wontons.", "Noodles", 4.5, 6.5, False, ["noodles", "pork", "wanton"]),
            D("Fishball Noodles", "Handmade fishballs with dry noodles and chilli.", "Noodles", 4, 6, True, ["noodles", "fish"]),
            D("Duck Rice", "Braised duck with herbal gravy over rice.", "Rice", 5, 8, False, ["duck", "rice", "braised"]),
            D("Roast Pork Rice", "Crackling roast pork belly with rice and sambal.", "Rice", 5, 8, False, ["pork", "rice", "roast"]),
            D("Nasi Lemak Set", "Coconut rice with fried chicken wing, egg and sambal.", "Rice", 4.5, 7, True, ["rice", "coconut", "sambal"]),
            D("Carrot Cake (Black)", "Fried radish cake with sweet dark sauce and egg.", "Mains", 4, 6, False, ["radish cake", "egg", "wok hei"]),
            D("Oyster Omelette", "Crispy egg and starch omelette with fresh oysters.", "Mains", 6, 10, True, ["oyster", "egg", "seafood"]),
            D("Satay (10 sticks)", "Charcoal-grilled chicken satay with peanut sauce.", "Mains", 7, 11, False, ["satay", "chicken", "grilled"]),
            D("Chicken Rice", "Poached chicken, fragrant rice and ginger chilli.", "Rice", 4, 6.5, False, ["chicken", "rice"]),
        ],
        laksa=[
            D("Curry Laksa", "Thick rice noodles in spicy coconut curry with prawns, tofu puffs and cockles.", "Noodles", 4.5, 7, True, ["laksa", "noodles", "coconut", "curry"]),
            D("Prawn Laksa", "Coconut curry laksa with fresh prawns and beansprouts.", "Noodles", 5.5, 8, True, ["laksa", "noodles", "coconut", "prawn"]),
            D("Assam Laksa", "Tangy tamarind fish broth with thick noodles, pineapple and mint.", "Noodles", 4.5, 7, True, ["laksa", "noodles", "tamarind", "fish"]),
        ],
        sides=[D("Fried Fishcake (4 pcs)", "Bouncy fried fishcake slices.", "Sides", 2, 3.5, False, ["fish"]),
               D("Chilli Sauce (extra)", "House chilli, extra garlicky.", "Sides", 0.5, 1, True, ["chilli"]),
               D("Braised Egg", "Soy-braised egg.", "Sides", 1, 1.5, False, ["egg"]),
               D("Blanched Greens", "Choy sum with oyster sauce.", "Sides", 3, 4.5, False, ["vegetable"])],
    ),
    "Peranakan": dict(
        count=8, symbols=["leaf.fill", "fork.knife", "flame.fill"], colors=["teal", "purple", "rose"],
        price=[2, 2, 3], tags=["nyonya", "heritage", "rempah", "halal-friendly"],
        suffix=["Nyonya Kitchen", "Peranakan Kitchen", "Baba Nyonya Cafe", "Rempah House", "Nyonya Table"],
        blurbs=["Recipes handed down by a Nyonya grandmother. Try the {sig}.",
                "Spice pastes ground by hand each morning. The {sig} is a house favourite.",
                "Heritage Peranakan cooking in {area}. Start with the {sig}."],
        mains=[
            D("Ayam Buah Keluak", "Chicken braised with buah keluak in a tamarind gravy.", "Mains", 14, 20, False, ["chicken", "heritage", "tamarind"]),
            D("Nyonya Chicken Curry", "Mild coconut curry with potatoes.", "Mains", 12, 17, False, ["chicken", "curry", "coconut"]),
            D("Beef Rendang", "Slow-cooked beef in dry coconut spice paste.", "Mains", 14, 19, True, ["beef", "coconut", "spicy"]),
            D("Babi Pongteh", "Pork belly stewed with fermented bean paste.", "Mains", 13, 18, False, ["pork", "stew", "braised"]),
            D("Chap Chye", "Braised cabbage, glass noodles and mushrooms.", "Sides", 8, 12, False, ["vegetable", "braised"]),
            D("Itek Tim", "Duck and salted vegetable soup with sour plum.", "Mains", 12, 17, False, ["duck", "soup"]),
            D("Sambal Petai Prawns", "Prawns wok-fried with stink beans and sambal.", "Mains", 15, 22, True, ["prawn", "seafood", "sambal"]),
            D("Nasi Ulam", "Herb rice salad with dried prawn and torch ginger.", "Rice", 7, 11, False, ["rice", "herb"]),
            D("Kueh Pie Tee (8 pcs)", "Crisp cups of braised turnip and prawn.", "Snacks", 8, 12, False, ["snack", "prawn"]),
            D("Otak-otak (3 pcs)", "Grilled fish paste in banana leaf.", "Snacks", 6, 9, True, ["fish", "snack", "grilled"]),
            D("Nasi Kunyit Set", "Turmeric glutinous rice with curry chicken and achar.", "Sets", 12, 16, False, ["rice", "chicken", "curry"]),
        ],
        sides=[D("Acar Awak", "Pickled vegetables with peanuts.", "Sides", 3, 5, False, ["pickle", "vegetable"]),
               D("Sambal Belacan", "Fiery shrimp paste chilli.", "Sides", 1, 2, True, ["sambal", "chilli"]),
               D("Steamed White Rice", "Fragrant jasmine rice.", "Sides", 1, 1.5, False, ["rice"])],
        desserts=[D("Kueh Salat (slice)", "Pandan custard on glutinous rice.", "Desserts", 2.5, 4, False, ["kueh", "pandan"]),
                  D("Bubur Cha Cha", "Warm coconut dessert with sweet potato and yam.", "Desserts", 3.5, 5.5, False, ["coconut", "sweet potato"])],
        laksa=[
            D("Katong Laksa", "Short rice noodles in rich coconut curry broth with prawns, cockles and fishcake.", "Noodles", 6.5, 9.5, True, ["laksa", "noodles", "coconut", "curry"]),
            D("Nyonya Curry Laksa", "Thick noodles in a spiced coconut curry with tau pok and egg.", "Noodles", 6.5, 9.5, True, ["laksa", "noodles", "coconut", "curry"]),
            D("Laksa Lemak with Prawns", "Creamy coconut laksa topped with fresh prawns.", "Noodles", 8, 11, True, ["laksa", "noodles", "coconut", "prawn"]),
            D("Vegetarian Laksa", "Coconut curry laksa with tofu puffs and beansprouts.", "Noodles", 6, 8.5, False, ["laksa", "noodles", "coconut", "vegetarian"]),
        ],
    ),
    "Malay": dict(
        count=9, symbols=["flame.fill", "fork.knife", "leaf.fill"], colors=["green", "olive", "orange"],
        price=[1, 1, 2], tags=["halal", "malay", "sambal", "kampung"],
        suffix=["Warung", "Nasi Padang", "Kampung Kitchen", "Dapur", "Nasi Lemak Corner"],
        blurbs=["Halal kampung cooking in {area}. The {sig} is the star.",
                "Open for late suppers. Order the {sig} with extra sambal.",
                "Padang-style spreads and homely rice dishes. Try the {sig}."],
        mains=[
            D("Nasi Lemak Ayam Goreng", "Coconut rice, fried chicken, ikan bilis and sambal.", "Rice", 5, 8, True, ["rice", "coconut", "chicken", "sambal"]),
            D("Mee Rebus", "Yellow noodles in sweet potato gravy with egg.", "Noodles", 4.5, 6.5, False, ["noodles", "egg", "gravy"]),
            D("Mee Soto", "Chicken noodle soup with lime and sambal.", "Noodles", 4.5, 6.5, False, ["noodles", "chicken", "soup"]),
            D("Beef Rendang Rice", "Tender beef rendang with rice and vegetables.", "Rice", 6, 9, True, ["beef", "rice", "coconut"]),
            D("Ayam Penyet", "Smashed fried chicken with sambal and tempeh.", "Rice", 6, 9, True, ["chicken", "fried", "sambal"]),
            D("Nasi Goreng Kampung", "Village-style fried rice with anchovies and egg.", "Rice", 5, 7.5, True, ["rice", "wok hei", "egg"]),
            D("Lontong", "Rice cakes in vegetable coconut gravy.", "Mains", 4.5, 6.5, False, ["rice cake", "coconut", "vegetable"]),
            D("Sambal Stingray", "Grilled stingray smothered in sambal.", "Mains", 12, 18, True, ["seafood", "fish", "sambal", "grilled"]),
            D("Satay Ayam (10 sticks)", "Chicken satay with peanut gravy.", "Mains", 7, 10, False, ["satay", "chicken", "grilled"]),
            D("Mee Goreng Mamak", "Spicy fried yellow noodles with tofu and egg.", "Noodles", 4.5, 7, True, ["noodles", "wok hei"]),
            D("Gado-gado", "Vegetables and tofu with peanut dressing.", "Mains", 5, 8, False, ["vegetable", "peanut", "tofu"]),
        ],
        sides=[D("Begedil (3 pcs)", "Spiced potato patties.", "Sides", 2, 3, False, ["potato"]),
               D("Sambal Telur", "Hard-boiled egg in chilli sambal.", "Sides", 1.5, 2.5, True, ["egg", "sambal"]),
               D("Keropok", "Crispy fish crackers.", "Snacks", 1.5, 3, False, ["snack", "fish"])],
        desserts=[D("Kuih Talam", "Pandan and coconut layered kuih.", "Desserts", 1.5, 2.5, False, ["kuih", "coconut"]),
                  D("Bubur Pulut Hitam", "Black glutinous rice dessert with coconut milk.", "Desserts", 3, 4.5, False, ["coconut", "dessert"])],
        laksa=[
            D("Laksa Johor", "Spaghetti with fish gravy, coconut and fresh herbs.", "Noodles", 6, 9, True, ["laksa", "noodles", "coconut", "fish"]),
            D("Curry Laksa", "Thick coconut curry broth with prawns, tofu puffs and cockles.", "Noodles", 5.5, 8, True, ["laksa", "noodles", "coconut", "curry"]),
            D("Laksa Lemak", "Creamy coconut laksa with fish cake.", "Noodles", 5.5, 8, True, ["laksa", "noodles", "coconut", "fishcake"]),
        ],
    ),
    "Indian": dict(
        count=10, symbols=["flame.fill", "fork.knife", "leaf.fill"], colors=["amber", "red", "coral"],
        price=[1, 2, 2], tags=["north indian", "south indian", "curry", "halal-friendly"],
        suffix=["Biryani House", "Curry Point", "Indian Kitchen", "Tandoor", "Dosa Corner"],
        blurbs=["Slow-cooked curries and fresh-off-the-tawa breads in {area}. Order the {sig}.",
                "Little India flavours, delivered hot. The {sig} is a crowd pleaser.",
                "Fragrant spices, generous portions. Try the {sig}."],
        mains=[
            D("Chicken Biryani", "Basmati rice layered with spiced chicken and raita.", "Rice", 7, 11, True, ["biryani", "rice", "chicken"]),
            D("Mutton Biryani", "Slow-cooked mutton biryani with egg.", "Rice", 9, 13, True, ["biryani", "rice", "mutton"]),
            D("Butter Chicken", "Tandoori chicken in creamy tomato gravy.", "Mains", 9, 14, False, ["chicken", "curry", "creamy"]),
            D("Palak Paneer", "Cottage cheese in spinach gravy.", "Mains", 8, 12, False, ["vegetarian", "curry", "paneer"]),
            D("Masala Dosa", "Crisp crepe with spiced potato filling.", "Mains", 4.5, 7, False, ["dosa", "vegetarian", "potato"]),
            D("Roti Prata (2 pcs)", "Flaky flatbread with dhal.", "Mains", 3, 5, False, ["prata", "flatbread"]),
            D("Fish Head Curry", "Red snapper head in tangy tamarind curry.", "Mains", 22, 30, True, ["fish", "curry", "tamarind"]),
            D("Tandoori Chicken Set", "Half tandoori chicken, naan and salad.", "Sets", 12, 17, True, ["chicken", "tandoori", "naan"]),
            D("Chana Masala", "Chickpeas in tomato and onion gravy.", "Mains", 6, 9, True, ["vegetarian", "curry", "chickpea"]),
            D("Garlic Naan", "Tandoor-baked garlic flatbread.", "Sides", 2.5, 4, False, ["naan", "flatbread"]),
            D("Thosai Set", "Thosai with sambar, coconut and tomato chutney.", "Sets", 5, 8, False, ["dosa", "vegetarian", "coconut"]),
            D("Mutton Briyani Set", "Mutton biryani with papadum and dalcha.", "Sets", 10, 14, True, ["biryani", "mutton"]),
        ],
        sides=[D("Papadum", "Crisp lentil wafers.", "Sides", 1.5, 2.5, False, ["snack"]),
               D("Raita", "Cooling yoghurt with cucumber.", "Sides", 2, 3, False, ["yoghurt"]),
               D("Samosa (2 pcs)", "Potato and pea pastries.", "Snacks", 2.5, 4, False, ["snack", "potato"])],
        drinks=[D("Mango Lassi", "Chilled yoghurt and mango drink.", "Drinks", 3.5, 5, False, ["mango", "yoghurt"]),
                D("Masala Chai", "Spiced milk tea.", "Drinks", 2, 3.5, False, ["tea", "spice"]),
                D("Teh Tarik", "Frothy pulled milk tea.", "Drinks", 1.8, 2.8, False, ["tea"])],
        desserts=[D("Gulab Jamun (2 pcs)", "Warm milk dumplings in syrup.", "Desserts", 3, 4.5, False, ["dessert", "syrup"])],
    ),
    "Chinese": dict(
        count=10, symbols=["fork.knife", "takeoutbag.and.cup.and.straw.fill", "fish.fill"], colors=["red", "navy", "orange"],
        price=[1, 2, 2, 3], tags=["chinese", "zi char", "cantonese", "family"],
        suffix=["Zi Char", "Restaurant", "Eating House", "Roast & Noodle", "Dim Sum House"],
        blurbs=["Wok-hei classics for the whole table. Our {sig} is the one to try.",
                "Cantonese comfort food in {area}. Start with the {sig}.",
                "Zi char for sharing, ready in 30 minutes. Order the {sig}."],
        mains=[
            D("Sweet and Sour Pork", "Crisp pork in tangy tomato sauce.", "Mains", 12, 17, False, ["pork", "sweet sour"]),
            D("Salted Egg Yolk Prawns", "Prawns coated in salted egg and curry leaves.", "Mains", 16, 24, False, ["prawn", "seafood", "egg"]),
            D("Hor Fun (Beef)", "Silky rice noodles in egg gravy.", "Noodles", 8, 13, False, ["noodles", "beef", "gravy"]),
            D("Yang Zhou Fried Rice", "Egg fried rice with prawns and char siu.", "Rice", 7, 11, False, ["rice", "egg", "wok hei"]),
            D("Har Gow (4 pcs)", "Steamed prawn dumplings.", "Snacks", 4.5, 7, False, ["dim sum", "prawn"]),
            D("Siew Mai (4 pcs)", "Steamed pork and mushroom dumplings.", "Snacks", 4.5, 7, False, ["dim sum", "pork"]),
            D("Char Siew Roast Combo", "Char siew and roast duck over rice.", "Rice", 6, 10, False, ["pork", "duck", "rice", "roast"]),
            D("Black Pepper Crab", "Whole crab wok-fried in black pepper sauce.", "Mains", 38, 58, True, ["crab", "seafood", "pepper"]),
            D("Sambal Kangkong", "Water spinach fried with belacan.", "Sides", 8, 12, True, ["vegetable", "sambal"]),
            D("Claypot Tofu", "Egg tofu and mushrooms in claypot.", "Mains", 10, 15, False, ["tofu", "vegetarian", "claypot"]),
            D("Fried Hokkien Prawn Mee", "Wok-fried noodles in rich prawn stock.", "Noodles", 8, 13, False, ["noodles", "prawn", "wok hei"]),
            D("Steamed Fish (Teochew)", "Steamed pomfret with sour plum and tomatoes.", "Mains", 22, 36, False, ["fish", "seafood", "steamed"]),
        ],
        sides=[D("Steamed Rice", "Fluffy white rice.", "Sides", 1, 1.5, False, ["rice"]),
               D("Century Egg Tofu", "Cold tofu topped with century egg.", "Sides", 5, 7, False, ["tofu", "egg"]),
               D("Spring Rolls (3 pcs)", "Crisp vegetable rolls.", "Snacks", 4, 6, False, ["snack", "vegetable"])],
        laksa=[
            D("Seafood Laksa", "Coconut curry broth with prawns, squid and fish cake.", "Noodles", 9, 13, True, ["laksa", "noodles", "coconut", "seafood"]),
            D("Curry Laksa", "Thick noodles in lemak curry with tofu puffs and cockles.", "Noodles", 6.5, 9.5, True, ["laksa", "noodles", "coconut", "curry"]),
            D("Dry Laksa", "Tossed noodles with laksa paste, prawns and bean sprouts.", "Noodles", 6.5, 9.5, True, ["laksa", "noodles", "prawn", "curry"]),
        ],
    ),
    "Sichuan": dict(
        count=5, symbols=["flame.fill", "flame.fill", "fork.knife"], colors=["red", "pink", "coral"],
        price=[2, 2, 3], tags=["sichuan", "mala", "numbing spicy", "hotpot"],
        suffix=["Mala Kitchen", "Chuan Cai", "Spicy House", "Hotpot Corner", "Mala Bar"],
        blurbs=["Numbing, fiery and fragrant. The {sig} is our signature.",
                "Sichuan peppercorns, dried chillies and a lot of wok. Order the {sig}.",
                "Heat that builds slowly in {area}. Start with the {sig}."],
        mains=[
            D("Mala Xiang Guo (Small)", "Pick-your-own dry stir-fry, small.", "Mains", 11, 15, True, ["mala", "stir-fry", "spicy"]),
            D("Mala Tang", "Spicy peppercorn soup with your pick of skewers.", "Mains", 10, 15, True, ["mala", "soup", "spicy"]),
            D("Mapo Tofu", "Silken tofu in chilli bean sauce with minced pork.", "Mains", 9, 14, True, ["tofu", "pork", "spicy"]),
            D("Kung Pao Chicken", "Chicken with peanuts and dried chillies.", "Mains", 10, 15, True, ["chicken", "peanut", "spicy"]),
            D("Dan Dan Noodles", "Noodles in a sesame chilli sauce.", "Noodles", 7, 10, True, ["noodles", "sesame", "spicy"]),
            D("Boiled Fish in Chilli Oil", "Fish fillets poached in numbing chilli oil.", "Mains", 22, 30, True, ["fish", "chilli oil", "spicy"]),
            D("Twice-cooked Pork", "Pork belly stir-fried with leeks and chilli bean paste.", "Mains", 12, 17, True, ["pork", "spicy"]),
            D("Cumin Lamb Skewers (5 pcs)", "Grilled lamb skewers dusted with cumin.", "Snacks", 8, 12, True, ["lamb", "grilled", "skewer"]),
            D("Chongqing Chicken", "Crispy chicken buried in dried chillies.", "Mains", 14, 20, True, ["chicken", "spicy", "fried"]),
        ],
        sides=[D("Smashed Cucumber", "Cold cucumber with garlic and vinegar.", "Sides", 4, 6, False, ["cucumber", "vegetable"]),
               D("Steamed Rice", "Plain white rice.", "Sides", 1, 1.5, False, ["rice"]),
               D("Spring Onion Pancake", "Flaky pan-fried pancake.", "Snacks", 4, 6, False, ["snack"])],
        drinks=[D("Chrysanthemum Tea", "Good for putting out the fire.", "Drinks", 1.8, 3, False, ["tea"]),
                D("Sour Plum Drink", "Chilled ume drink.", "Drinks", 2.5, 3.5, False, ["plum"])],
    ),
    "Japanese": dict(
        count=7, symbols=["fish.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill"], colors=["navy", "red", "violet"],
        price=[2, 3, 3, 4], tags=["japanese", "sushi", "donburi", "washoku"],
        suffix=["Sushi Bar", "Don House", "Izakaya", "Ramen-ya", "Washoku Kitchen"],
        blurbs=["Simple, seasonal Japanese food in {area}. The {sig} is a favourite.",
                "Rice bowls and noodles made to order. Try the {sig}.",
                "Counter-style Japanese comfort food. Order the {sig}."],
        mains=[
            D("Salmon Sashimi Don", "Fresh salmon slices over seasoned rice.", "Rice", 14, 20, False, ["sashimi", "salmon", "rice"]),
            D("Chicken Katsu Curry", "Panko chicken cutlet with Japanese curry.", "Rice", 10, 15, False, ["chicken", "curry", "fried"]),
            D("Tonkotsu Ramen", "Pork bone broth ramen with chashu and egg.", "Noodles", 12, 17, False, ["ramen", "pork", "noodles"]),
            D("Spicy Miso Ramen", "Miso broth with chilli mince.", "Noodles", 12, 17, True, ["ramen", "miso", "noodles"]),
            D("Unagi Don", "Grilled eel over rice with sweet soy glaze.", "Rice", 18, 26, False, ["eel", "rice", "grilled"]),
            D("Gyudon", "Sliced beef and onions simmered in sweet soy.", "Rice", 8, 12, False, ["beef", "rice"]),
            D("Assorted Sushi (10 pcs)", "Chef's selection of nigiri.", "Sets", 18, 28, False, ["sushi", "fish"]),
            D("Tempura Udon", "Udon in dashi with prawn tempura.", "Noodles", 10, 15, False, ["udon", "prawn", "noodles"]),
            D("Chirashi Don", "Assorted sashimi over sushi rice.", "Rice", 18, 28, False, ["sashimi", "rice"]),
            D("Karaage Set", "Japanese fried chicken with rice and miso soup.", "Sets", 10, 15, False, ["chicken", "fried", "rice"]),
            D("Takoyaki (6 pcs)", "Octopus balls with mayo and bonito.", "Snacks", 5, 8, False, ["octopus", "snack"]),
        ],
        sides=[D("Edamame", "Salted soybeans.", "Sides", 3, 5, False, ["vegetable"]),
               D("Miso Soup", "Tofu and seaweed miso soup.", "Sides", 2, 3.5, False, ["soup", "tofu"]),
               D("Gyoza (5 pcs)", "Pan-fried pork dumplings.", "Snacks", 5, 8, False, ["dumpling", "pork"])],
        drinks=[D("Hot Green Tea", "Roasted Japanese tea.", "Drinks", 1.5, 3, False, ["tea"]),
                D("Ramune", "Japanese marble soda.", "Drinks", 2.8, 4, False, ["soda"]),
                D("Iced Matcha Latte", "Matcha with fresh milk.", "Drinks", 4.5, 6.5, False, ["matcha"])],
        desserts=[D("Matcha Mochi (3 pcs)", "Chewy mochi with red bean.", "Desserts", 4, 6, False, ["matcha", "mochi"])],
    ),
    "Korean": dict(
        count=6, symbols=["flame.fill", "fork.knife", "takeoutbag.and.cup.and.straw.fill"], colors=["rose", "red", "violet"],
        price=[2, 2, 3], tags=["korean", "kimchi", "bbq", "k-food"],
        suffix=["Korean Kitchen", "BBQ House", "Bibimbap Bar", "Soondubu", "Pocha"],
        blurbs=["Sizzling Korean comfort food in {area}. Try the {sig}.",
                "Stews, BBQ and banchan. The {sig} is the one to order.",
                "Seoul street food, Singapore heat. Order the {sig}."],
        mains=[
            D("Bibimbap", "Rice with seasoned vegetables, beef and gochujang.", "Rice", 10, 15, True, ["rice", "beef", "gochujang"]),
            D("Kimchi Jjigae", "Kimchi stew with pork and tofu.", "Mains", 10, 15, True, ["kimchi", "stew", "pork"]),
            D("Army Stew (Budae Jjigae)", "Spicy stew with sausage, noodles and cheese.", "Mains", 14, 20, True, ["stew", "noodles", "spicy"]),
            D("Korean Fried Chicken", "Double-fried chicken glazed in sweet chilli.", "Mains", 12, 18, True, ["chicken", "fried", "gochujang"]),
            D("Bulgogi Beef Set", "Marinated beef with rice and banchan.", "Sets", 13, 18, False, ["beef", "grilled", "rice"]),
            D("Japchae", "Glass noodles with vegetables and sesame.", "Noodles", 8, 12, False, ["noodles", "vegetable", "sesame"]),
            D("Tteokbokki", "Rice cakes in spicy gochujang sauce.", "Snacks", 6, 9, True, ["rice cake", "gochujang", "spicy"]),
            D("Samgyeopsal Set", "Grilled pork belly with lettuce wraps.", "Sets", 15, 22, False, ["pork", "grilled", "bbq"]),
            D("Cold Noodles (Naengmyeon)", "Chilled buckwheat noodles in tangy broth.", "Noodles", 9, 13, False, ["noodles", "cold"]),
            D("Kimchi Fried Rice", "Fried rice with kimchi and egg.", "Rice", 8, 12, True, ["rice", "kimchi", "egg"]),
        ],
        sides=[D("Kimchi", "Fermented napa cabbage.", "Sides", 2, 4, True, ["kimchi", "vegetable"]),
               D("Steamed Egg", "Fluffy savoury egg custard.", "Sides", 4, 6, False, ["egg"]),
               D("Mandu (5 pcs)", "Pan-fried Korean dumplings.", "Snacks", 5, 8, False, ["dumpling"])],
        drinks=[D("Barley Tea", "Roasted barley tea.", "Drinks", 1.5, 2.5, False, ["tea"]),
                D("Yuja Citron Tea", "Honeyed citron tea.", "Drinks", 3.5, 5, False, ["citron"])],
    ),
    "Thai": dict(
        count=6, symbols=["leaf.fill", "flame.fill", "fork.knife"], colors=["green", "amber", "teal"],
        price=[1, 2, 2], tags=["thai", "tom yum", "street food", "herbs"],
        suffix=["Thai Kitchen", "Thai Street Food", "Thai Express Cafe", "Bangkok Corner", "Thai Garden"],
        blurbs=["Sour, sweet, salty and spicy in perfect balance. Try the {sig}.",
                "Bangkok street flavours in {area}. The {sig} is the favourite.",
                "Fresh herbs, bold chilli. Order the {sig}."],
        mains=[
            D("Pad Thai", "Wok-fried rice noodles with prawns and peanuts.", "Noodles", 8, 12, False, ["noodles", "prawn", "peanut"]),
            D("Tom Yum Soup", "Hot and sour soup with prawns and mushrooms.", "Mains", 9, 14, True, ["soup", "prawn", "spicy"]),
            D("Green Curry Chicken", "Coconut green curry with Thai basil.", "Mains", 9, 14, True, ["curry", "coconut", "chicken"]),
            D("Basil Pork Rice (Pad Kra Pao)", "Minced pork with holy basil and fried egg.", "Rice", 7, 10, True, ["pork", "rice", "basil", "egg"]),
            D("Mango Sticky Rice", "Sweet glutinous rice with ripe mango.", "Desserts", 5, 8, False, ["mango", "coconut", "dessert"]),
            D("Boat Noodles", "Rich, dark beef broth with rice noodles.", "Noodles", 6, 9, True, ["noodles", "beef", "soup"]),
            D("Pineapple Fried Rice", "Fried rice with pineapple, cashews and prawns.", "Rice", 8, 12, False, ["rice", "pineapple", "prawn"]),
            D("Som Tam", "Green papaya salad with chilli and lime.", "Sides", 6, 9, True, ["salad", "papaya", "spicy"]),
            D("Massaman Beef Curry", "Mild peanut curry with potatoes.", "Mains", 11, 16, False, ["curry", "beef", "peanut"]),
            D("Thai Fish Cake (4 pcs)", "Spiced fish cakes with cucumber relish.", "Snacks", 6, 9, True, ["fish", "snack"]),
        ],
        sides=[D("Jasmine Rice", "Steamed Thai jasmine rice.", "Sides", 1, 2, False, ["rice"]),
               D("Chicken Satay (4 sticks)", "Grilled satay with peanut sauce.", "Snacks", 5, 8, False, ["chicken", "satay"]),
               D("Fried Egg", "Crispy-edged fried egg.", "Sides", 1, 2, False, ["egg"])],
        drinks=[D("Thai Milk Tea", "Iced orange milk tea.", "Drinks", 3, 4.5, False, ["tea", "milk"]),
                D("Lemongrass Drink", "Cold lemongrass with honey.", "Drinks", 2.5, 3.5, False, ["lemongrass"])],
    ),
    "Western": dict(
        count=7, symbols=["fork.knife", "takeoutbag.and.cup.and.straw.fill", "fork.knife"], colors=["navy", "brown", "blue"],
        price=[2, 2, 3, 3], tags=["western", "grill", "comfort food", "burgers"],
        suffix=["Grill", "Burger Bar", "Western Food", "Chophouse", "Diner"],
        blurbs=["Hawker-style Western with generous portions. Try the {sig}.",
                "Grilled to order in {area}. The {sig} is a bestseller.",
                "Comfort food, no fuss. Order the {sig}."],
        mains=[
            D("Chicken Chop", "Grilled chicken chop with fries and coleslaw.", "Mains", 8, 12, False, ["chicken", "grilled", "fries"]),
            D("Fish and Chips", "Beer-battered fish with fries and tartar sauce.", "Mains", 9, 14, False, ["fish", "fried", "fries"]),
            D("Beef Burger", "Beef patty, cheddar and caramelised onions.", "Mains", 10, 16, False, ["burger", "beef", "cheese"]),
            D("Spaghetti Bolognese", "Beef ragu over spaghetti.", "Noodles", 9, 14, False, ["pasta", "beef"]),
            D("Aglio Olio Prawns", "Garlic and chilli spaghetti with prawns.", "Noodles", 11, 16, True, ["pasta", "prawn", "garlic"]),
            D("Ribeye Steak (200g)", "Grilled ribeye with fries and salad.", "Mains", 22, 34, False, ["beef", "steak", "grilled"]),
            D("Chicken Wings (6 pcs)", "Crispy wings with buffalo or honey glaze.", "Snacks", 7, 11, False, ["chicken", "wings", "fried"]),
            D("Mushroom Soup", "Creamy mushroom soup with garlic bread.", "Sides", 5, 8, False, ["soup", "mushroom"]),
            D("Pork Chop", "Breaded pork chop with baked beans.", "Mains", 9, 13, False, ["pork", "fried"]),
            D("Caesar Salad", "Romaine, bacon and parmesan.", "Sides", 7, 11, False, ["salad", "cheese"]),
            D("Carbonara", "Creamy bacon spaghetti with egg yolk.", "Noodles", 10, 15, False, ["pasta", "bacon", "egg"]),
        ],
        sides=[D("Truffle Fries", "Fries with truffle oil and parmesan.", "Sides", 5, 8, False, ["fries", "cheese"]),
               D("Coleslaw", "Creamy cabbage slaw.", "Sides", 2, 3.5, False, ["salad"]),
               D("Garlic Bread", "Toasted garlic butter bread.", "Sides", 3, 5, False, ["bread"])],
        drinks=[D("Iced Lemon Tea", "Freshly brewed.", "Drinks", 2.5, 3.5, False, ["tea", "lemon"]),
                D("Coke Float", "Cola with vanilla ice cream.", "Drinks", 3.5, 5, False, ["soda"])],
        desserts=[D("Chocolate Lava Cake", "Warm cake with molten centre.", "Desserts", 6, 9, False, ["chocolate", "cake"])],
    ),
    "Desserts": dict(
        count=5, symbols=["birthday.cake.fill", "birthday.cake.fill", "cup.and.saucer.fill"], colors=["pink", "rose", "violet"],
        price=[1, 2, 2], tags=["dessert", "sweet", "cakes", "kueh"],
        suffix=["Dessert Bar", "Sweets", "Patisserie", "Kueh House", "Ice Kachang Stall"],
        blurbs=["Sweet treats for every craving. The {sig} sells out early.",
                "Traditional and modern desserts in {area}. Try the {sig}.",
                "Made fresh each morning. Start with the {sig}."],
        mains=[
            D("Ice Kachang", "Shaved ice with red bean, corn and gula melaka.", "Desserts", 3, 5, False, ["shaved ice", "red bean"]),
            D("Chendol", "Pandan jelly and coconut milk over shaved ice.", "Desserts", 3, 5, False, ["coconut", "pandan", "shaved ice"]),
            D("Mango Pomelo Sago", "Chilled mango soup with pomelo and sago.", "Desserts", 5, 7.5, False, ["mango", "pomelo", "sago"]),
            D("Durian Pengat", "Warm durian dessert with coconut cream.", "Desserts", 6, 9, False, ["durian", "coconut"]),
            D("Orh Nee", "Silky yam paste with ginkgo nuts.", "Desserts", 4, 6, False, ["yam", "dessert"]),
            D("Tau Huay", "Warm silken beancurd with ginger syrup.", "Desserts", 2, 3.5, False, ["beancurd", "ginger"]),
            D("Burnt Cheesecake (slice)", "Basque-style cheesecake.", "Desserts", 6, 9, False, ["cheesecake", "cake"]),
            D("Kueh Lapis", "Layered steamed cake.", "Desserts", 2.5, 4, False, ["kueh", "cake"]),
            D("Waffle with Ice Cream", "Crisp waffle, two scoops and syrup.", "Desserts", 6, 10, False, ["waffle", "ice cream"]),
            D("Ondeh Ondeh (6 pcs)", "Pandan balls with gula melaka.", "Snacks", 4, 6, False, ["pandan", "kueh", "coconut"]),
        ],
        sides=[D("Extra Ice Cream Scoop", "Vanilla or chocolate.", "Sides", 1.5, 2.5, False, ["ice cream"]),
               D("Pandan Chiffon (slice)", "Light and fluffy.", "Snacks", 2.5, 4, False, ["pandan", "cake"])],
        drinks=[D("Bandung", "Rose syrup milk.", "Drinks", 2, 3.5, False, ["rose", "milk"]),
                D("Sugarcane Juice", "Freshly pressed.", "Drinks", 2, 3.5, False, ["sugarcane"])],
    ),
    "Coffee shop": dict(
        count=5, symbols=["cup.and.saucer.fill", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill"], colors=["brown", "amber", "coral"],
        price=[1, 1, 2], tags=["kopitiam", "breakfast", "coffee", "toast"],
        suffix=["Kopitiam", "Coffee Stall", "Toast House", "Coffee & Toast", "Kopi Corner"],
        blurbs=["Old-school kopitiam breakfasts in {area}. Try the {sig}.",
                "Charcoal-roasted kopi and warm toast. Order the {sig}.",
                "Open from dawn. The {sig} is what the regulars have."],
        mains=[
            D("Kaya Toast Set", "Kaya toast, two soft-boiled eggs and a kopi.", "Sets", 4.5, 6.5, False, ["toast", "egg", "coffee", "kaya"]),
            D("French Toast", "Fried toast with kaya and butter.", "Mains", 3, 5, False, ["toast", "kaya"]),
            D("Mee Siam", "Tangy vermicelli with egg and tau pok.", "Noodles", 4, 6, True, ["noodles", "egg"]),
            D("Mee Rebus", "Yellow noodles in sweet potato gravy.", "Noodles", 4, 6, False, ["noodles", "egg"]),
            D("Nasi Lemak Breakfast", "Coconut rice, ikan bilis and egg.", "Rice", 3.5, 5.5, True, ["rice", "coconut", "egg"]),
            D("Half-boiled Eggs (2)", "Soft-boiled eggs with soy and pepper.", "Sides", 1.8, 2.5, False, ["egg"]),
            D("Curry Puff (2 pcs)", "Flaky pastry with curried potato.", "Snacks", 2.5, 4, True, ["curry", "snack", "potato"]),
            D("Peanut Butter Toast", "Thick-cut toast with peanut butter.", "Mains", 2.5, 4, False, ["toast", "peanut"]),
            D("Lor Mee", "Thick noodles in starchy gravy.", "Noodles", 4.5, 6.5, False, ["noodles", "gravy"]),
        ],
        sides=[D("Kaya Butter Bun", "Soft bun with kaya and butter slab.", "Snacks", 1.8, 3, False, ["kaya", "bun"]),
               D("Soft-boiled Egg (1)", "Single soft-boiled egg.", "Sides", 0.9, 1.5, False, ["egg"])],
        drinks=[D("Kopi", "Coffee with condensed milk.", "Drinks", 1.4, 2, False, ["coffee"]),
                D("Kopi O Kosong", "Black coffee, no sugar.", "Drinks", 1.2, 1.8, False, ["coffee"]),
                D("Teh Peng", "Iced milk tea.", "Drinks", 1.8, 2.5, False, ["tea"]),
                D("Milo Dinosaur", "Iced Milo with Milo powder.", "Drinks", 3, 4, False, ["milo"]),
                D("Yuan Yang", "Coffee and tea mixed.", "Drinks", 1.8, 2.6, False, ["coffee", "tea"])],
    ),
    "Salads": dict(
        count=2, symbols=["leaf.fill"], colors=["green", "olive", "teal"],
        price=[2, 3], tags=["healthy", "salads", "vegetarian", "bowls"],
        suffix=["Salad Bar", "Bowl Co", "Greens"],
        blurbs=["Fresh bowls built your way in {area}. The {sig} is popular.",
                "Lighter plates, big flavours. Try the {sig}."],
        mains=[
            D("Grilled Chicken Bowl", "Brown rice, grilled chicken and greens.", "Mains", 11, 15, False, ["chicken", "bowl", "healthy"]),
            D("Quinoa Falafel Bowl", "Quinoa, falafel and hummus.", "Mains", 11, 15, False, ["quinoa", "vegetarian", "bowl"]),
            D("Salmon Poke Bowl", "Salmon, avocado and edamame over rice.", "Mains", 14, 19, False, ["salmon", "bowl", "rice"]),
            D("Tofu Teriyaki Bowl", "Teriyaki tofu with sesame greens.", "Mains", 10, 14, False, ["tofu", "vegetarian", "bowl"]),
            D("Caesar Chicken Salad", "Romaine, chicken and parmesan.", "Mains", 10, 14, False, ["salad", "chicken"]),
            D("Avocado Wrap", "Avocado, hummus and greens in a wrap.", "Mains", 8, 12, False, ["avocado", "vegetarian", "wrap"]),
            D("Sweet Potato Fries", "Baked sweet potato wedges.", "Sides", 4, 6, False, ["sweet potato"]),
        ],
        sides=[D("Fruit Cup", "Seasonal fruit.", "Sides", 3, 5, False, ["fruit"]),
               D("Boiled Egg (2)", "Protein add-on.", "Sides", 2, 3, False, ["egg"])],
        drinks=[D("Cold-pressed Juice", "Apple, carrot and ginger.", "Drinks", 5.5, 7.5, False, ["juice"]),
                D("Green Smoothie", "Spinach, apple and banana.", "Drinks", 5.5, 7.5, False, ["smoothie"])],
    ),
}

# Laksa specialists per cuisine (the first n stalls of that cuisine).
LAKSA_COUNTS = {"Peranakan": 4, "Hawker": 2, "Malay": 1, "Chinese": 1}

GENERIC_DRINKS = [
    D("Barley Water", "Homemade, lightly sweetened.", "Drinks", 1.6, 2.4, False, ["barley"]),
    D("Lime Juice", "Freshly squeezed.", "Drinks", 2, 3, False, ["lime"]),
    D("Soya Bean Milk", "Fresh, hot or cold.", "Drinks", 1.5, 2.2, False, ["soya"]),
    D("Iced Lemon Tea", "Freshly brewed.", "Drinks", 2, 3, False, ["tea", "lemon"]),
    D("Teh Peng", "Iced milk tea.", "Drinks", 1.8, 2.6, False, ["tea"]),
    D("Kopi", "Coffee with condensed milk.", "Drinks", 1.4, 2.2, False, ["coffee"]),
    D("Fresh Coconut", "Coconut water with flesh.", "Drinks", 3, 4.5, False, ["coconut"]),
    D("Sugarcane Juice", "Freshly pressed.", "Drinks", 2, 3.2, False, ["sugarcane"]),
]

OWNERS = [
    "Ah Seng", "Ah Hock", "Mdm Lim", "Uncle Ben", "Auntie Rose", "Lao Wang", "Mei Ling", "Ah Kow", "Mdm Tan", "Uncle Raj",
    "Auntie Siti", "Ah Beng", "Mdm Chua", "Pak Hassan", "Cik Aminah", "Aunty Devi", "Uncle Roy", "Ah Lian", "Mr Goh", "Mdm Ong",
    "Ah Huat", "Bro Kenji", "Mdm Kim", "Chef Somchai", "Uncle Max", "Ah Soon", "Mdm Yeo", "Encik Rahim", "Auntie Mary", "Ah Fatt",
    "Mr Ho", "Madam Sim", "Papa Joe", "Mama Lee", "Ah Girl", "Old Tan", "Little Ng", "Big Boy Ah Meng", "Mdm Foo", "Uncle Sam",
    "Ah Tong", "Mdm Soh", "Kakak Nora", "Bang Zul", "Mr Teo", "Ah Pek", "Mdm Wee", "Uncle Vee", "Auntie Grace", "Ah Chye",
    "Mr Han", "Mdm Seah", "Pak Samad", "Auntie Lily", "Ah Boon", "Mdm Quek", "Uncle Dave", "Ah Kiat", "Mdm Phua", "Mr Lau",
    "Kak Yati", "Abang Ali", "Mdm Toh", "Ah Leong", "Uncle Henry", "Auntie Jane", "Ah Sia", "Mdm Neo", "Mr Koh", "Ah Tee",
    "Mdm Heng", "Uncle Paul", "Ah Wee", "Mdm Low", "Mr Chew", "Chef Park", "Chef Tanaka", "Mdm Pang", "Ah Bee", "Uncle Gopal",
    "Auntie Ming", "Ah Chong", "Mdm Yap", "Mr Sia", "Pak Rashid", "Ah Keng", "Mdm Ang", "Uncle Leon", "Ah Meng", "Mdm Tay",
    "Mr Lee", "Ah Liang", "Mdm Poh", "Uncle Alan", "Chef Min", "Mdm Kwek", "Ah Hui", "Auntie Nana", "Mr Chin", "Ah Kok",
]

# r1-r5 keep their names, menus and item ids; r4 and r5 gain extra items.
BASE = [
    dict(id="r1", name="Ah Seng Chicken Rice", cuisine="Hawker", rating=4.6, deliveryMinutes=25, deliveryFee=2.99, isOpen=True,
         imageName="fork.knife", tags=["chicken rice", "hawker", "local favourites", "halal-friendly"],
         description="Poached and roasted chicken with fragrant rice, run by the same family for three generations.",
         area="Tiong Bahru", reviewCount=1840, priceLevel=1, colorHex="#E4572E",
         menu=[
             ("r1m1", "Steamed Chicken Rice", "Tender poached chicken with fragrant rice and chilli.", 4.5, "Mains", False, False, ["chicken", "rice"]),
             ("r1m2", "Roasted Chicken Rice", "Crispy-skinned roast chicken with fragrant rice.", 4.8, "Mains", False, False, ["chicken", "rice", "roast"]),
             ("r1m3", "Chicken Rice Set for 2", "Half a chicken, two rice, soup and greens.", 15.0, "Mains", False, False, ["chicken", "rice"]),
             ("r1m4", "Oyster Sauce Kailan", "Blanched kailan with oyster sauce.", 4.0, "Sides", False, False, ["vegetable"]),
             ("r1m5", "Braised Egg", "Soy-braised egg.", 1.2, "Sides", False, False, ["egg"]),
             ("r1m6", "Chilli Sauce (extra)", "Our house chilli. Very garlicky.", 0.5, "Sides", False, True, ["chilli"]),
             ("r1m7", "Barley Water", "Homemade, lightly sweetened.", 1.8, "Drinks", False, False, ["barley"]),
             ("r1m8", "Lime Juice", "Freshly squeezed.", 2.2, "Drinks", True, False, ["lime"]),
         ]),
    dict(id="r2", name="Mala Mama", cuisine="Sichuan", rating=4.3, deliveryMinutes=35, deliveryFee=3.49, isOpen=True,
         imageName="flame.fill", tags=["sichuan", "mala", "numbing spicy"],
         description="Pick-your-own mala stir-fry with proper numbing peppercorns and a heavy hand with the chilli.",
         area="Bugis", reviewCount=920, priceLevel=2, colorHex="#C8312B",
         menu=[
             ("r2m1", "Mala Xiang Guo (Small)", "Pick-your-own stir-fry, small bowl.", 12.9, "Mains", False, True, ["mala", "stir-fry", "spicy"]),
             ("r2m2", "Mala Xiang Guo (Large)", "Pick-your-own stir-fry, large bowl.", 18.9, "Mains", False, True, ["mala", "stir-fry", "spicy"]),
             ("r2m3", "Dan Dan Noodles", "Noodles in a nutty, spicy sauce.", 8.5, "Mains", False, True, ["noodles", "sesame", "spicy"]),
             ("r2m4", "Smashed Cucumber", "Cold cucumber with garlic and vinegar.", 4.5, "Sides", False, False, ["cucumber", "vegetable"]),
             ("r2m5", "Steamed Rice", "", 1.0, "Sides", False, False, ["rice"]),
             ("r2m6", "Chrysanthemum Tea", "Good for putting out the fire.", 2.0, "Drinks", False, False, ["tea"]),
         ]),
    dict(id="r3", name="Kopi Corner", cuisine="Coffee shop", rating=4.8, deliveryMinutes=15, deliveryFee=1.99, isOpen=True,
         imageName="cup.and.saucer.fill", tags=["kopitiam", "breakfast", "coffee", "toast"],
         description="Charcoal-roasted kopi, kaya toast and soft-boiled eggs, the way breakfast used to be.",
         area="Toa Payoh", reviewCount=2410, priceLevel=1, colorHex="#8B5E3C",
         menu=[
             ("r3m1", "Kaya Toast Set", "Kaya toast, two soft-boiled eggs and a kopi.", 5.6, "Breakfast", False, False, ["toast", "egg", "coffee", "kaya"]),
             ("r3m2", "Mee Siam", "Tangy vermicelli with egg and tau pok.", 5.0, "Breakfast", False, True, ["noodles", "egg"]),
             ("r3m3", "Kopi", "Coffee with condensed milk.", 1.6, "Drinks", False, False, ["coffee"]),
             ("r3m4", "Kopi O Kosong", "Black coffee, no sugar.", 1.4, "Drinks", False, False, ["coffee"]),
             ("r3m5", "Teh Peng", "Iced milk tea.", 2.0, "Drinks", False, False, ["tea"]),
             ("r3m6", "Milo Dinosaur", "Iced Milo with a mountain of Milo powder.", 3.5, "Drinks", False, False, ["milo"]),
         ]),
    dict(id="r4", name="Green Bowl", cuisine="Salads", rating=4.1, deliveryMinutes=30, deliveryFee=3.99, isOpen=False,
         imageName="leaf.fill", tags=["healthy", "salads", "vegetarian", "bowls"],
         description="Build-your-own bowls and cold-pressed juices. Closed for the evening.",
         area="Holland Village", reviewCount=310, priceLevel=3, colorHex="#2A9D6F",
         menu=[
             ("r4m1", "Build Your Own Bowl", "Base, protein and three toppings.", 13.5, "Bowls", False, False, ["bowl", "healthy"]),
             ("r4m2", "Sesame Tofu Bowl", "Brown rice, tofu, edamame and greens.", 12.0, "Bowls", False, False, ["tofu", "vegetarian", "bowl"]),
             ("r4m3", "Cold-pressed Juice", "Apple, carrot and ginger.", 6.5, "Drinks", False, False, ["juice"]),
             ("r4m4", "Quinoa Falafel Bowl", "Quinoa, falafel and hummus.", 13.0, "Bowls", False, False, ["quinoa", "vegetarian", "bowl"]),
             ("r4m5", "Grilled Chicken Bowl", "Brown rice, grilled chicken and greens.", 14.0, "Bowls", False, False, ["chicken", "bowl", "healthy"]),
             ("r4m6", "Green Smoothie", "Spinach, apple and banana.", 6.5, "Drinks", False, False, ["smoothie"]),
             ("r4m7", "Sweet Potato Wedges", "Baked and lightly salted.", 4.5, "Sides", False, False, ["sweet potato"]),
         ]),
    dict(id="r5", name="Ondeh Ondeh Bakery", cuisine="Desserts", rating=4.7, deliveryMinutes=40, deliveryFee=2.49, isOpen=True,
         imageName="birthday.cake.fill", tags=["dessert", "kueh", "cakes", "pandan"],
         description="Traditional kueh and pandan cakes baked fresh every morning with gula melaka and coconut.",
         area="Joo Chiat", reviewCount=1260, priceLevel=2, colorHex="#EF476F",
         menu=[
             ("r5m1", "Ondeh Ondeh (6 pcs)", "Pandan balls with gula melaka.", 4.8, "Kueh", False, False, ["pandan", "kueh", "coconut"]),
             ("r5m2", "Kueh Lapis", "Layered spice cake slice.", 3.2, "Kueh", False, False, ["kueh", "cake"]),
             ("r5m3", "Pandan Chiffon (whole)", "Light and fluffy.", 18.0, "Cakes", True, False, ["pandan", "cake"]),
             ("r5m4", "Pineapple Tarts (box)", "Twenty buttery tarts.", 22.0, "Cakes", False, False, ["pineapple", "cake"]),
             ("r5m5", "Kueh Salat (slice)", "Pandan custard on glutinous rice.", 2.8, "Kueh", False, False, ["kueh", "pandan"]),
             ("r5m6", "Ang Ku Kueh (4 pcs)", "Sweet red tortoise cakes with mung bean.", 5.6, "Kueh", False, False, ["kueh", "mung bean"]),
             ("r5m7", "Gula Melaka Chiffon (slice)", "Palm sugar chiffon with coconut cream.", 3.5, "Cakes", False, False, ["cake", "coconut"]),
         ]),
]


def price_between(rng, lo, hi):
    """A price in dollars, rounded to 0.05, as a float with at most 2 dp."""
    cents = rng.randint(int(round(lo * 100)), int(round(hi * 100)))
    cents = max(80, min(2800, int(round(cents / 5.0)) * 5))
    return cents / 100.0


def mk_item(rid, n, dish, rng, allow_sold_out=True):
    name, desc, cat, lo, hi, spicy, tags = dish
    sold_out = allow_sold_out and rng.random() < 0.04
    return dict(id="%sm%d" % (rid, n), name=name, description=desc, price=price_between(rng, lo, hi),
                category=cat, isSoldOut=sold_out, isSpicy=spicy, tags=sorted(set(tags)))


def regroup(items):
    """Stable sort by category so each section is contiguous, in CATEGORY_ORDER then first appearance."""
    seen = []
    for item in items:
        if item["category"] not in seen:
            seen.append(item["category"])
    known = [c for c in CATEGORY_ORDER if c in seen]
    order = known + [c for c in seen if c not in known]
    return sorted(items, key=lambda i: order.index(i["category"]))


def make_menu(rid, cuisine, cfg, laksa, rng):
    count = rng.randint(6, 12)
    chosen = []
    names = set()

    def take(dish):
        if dish[0] in names:
            return False
        names.add(dish[0])
        chosen.append(dish)
        return True

    if laksa:
        laksa_dishes = list(cfg["laksa"])
        rng.shuffle(laksa_dishes)
        for dish in laksa_dishes[:rng.randint(2, 3)]:
            take(dish)

    drinks = list(cfg.get("drinks", [])) + GENERIC_DRINKS
    rng.shuffle(drinks)
    drink_target = rng.randint(1, 2)
    sides = list(cfg["sides"])
    rng.shuffle(sides)
    side_target = rng.randint(1, 2)
    desserts = list(cfg.get("desserts", []))
    rng.shuffle(desserts)
    dessert_target = 1 if desserts and rng.random() < 0.6 else 0

    reserved = drink_target + side_target + dessert_target
    mains = list(cfg["mains"])
    rng.shuffle(mains)
    for dish in mains:
        if len(chosen) >= count - reserved:
            break
        take(dish)
    for dish in sides[:side_target] + desserts[:dessert_target]:
        take(dish)
    for dish in drinks:
        if len(chosen) >= count:
            break
        if sum(1 for c in chosen if c[2] == "Drinks") >= drink_target:
            break
        take(dish)
    # Top up to the target size if a pool ran out.
    for dish in mains + sides + drinks:
        if len(chosen) >= max(count, 6):
            break
        take(dish)

    chosen = chosen[:12]
    items = []
    for dish in chosen:
        is_laksa = "laksa" in dish[6]
        items.append((dish, is_laksa))
    # Build items in category order so ids follow the final order.
    ordered = regroup([dict(category=d[2], dish=d, laksa=l) for d, l in items])
    menu = []
    for index, entry in enumerate(ordered, start=1):
        menu.append(mk_item(rid, index, entry["dish"], rng, allow_sold_out=not entry["laksa"]))
    return menu


def restaurant_tags(cfg, menu, laksa, rng):
    tags = list(cfg["tags"][:2]) + [t for t in cfg["tags"][2:] if rng.random() < 0.5]
    if laksa:
        tags = ["laksa"] + tags
    counts = {}
    for item in menu:
        for tag in item["tags"]:
            counts[tag] = counts.get(tag, 0) + 1
    for tag, _ in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))[:2]:
        tags.append(tag)
    unique = []
    for tag in tags:
        if tag not in unique:
            unique.append(tag)
    return unique


def build():
    rng = random.Random(SEED)

    # Base restaurants first.
    restaurants = []
    for base in BASE:
        menu = []
        for (iid, name, desc, price, cat, sold, spicy, tags) in base["menu"]:
            menu.append(dict(id=iid, name=name, description=desc, price=price, category=cat,
                             isSoldOut=sold, isSpicy=spicy, tags=tags))
        restaurants.append(dict(
            id=base["id"], name=base["name"], cuisine=base["cuisine"], rating=base["rating"],
            deliveryMinutes=base["deliveryMinutes"], deliveryFee=base["deliveryFee"], isOpen=base["isOpen"],
            imageName=base["imageName"], tags=base["tags"], description=base["description"], area=base["area"],
            reviewCount=base["reviewCount"], priceLevel=base["priceLevel"], colorHex=base["colorHex"],
            menu=regroup(menu),
        ))

    # Plan r6..r100: a shuffled list of (cuisine, laksa?) slots.
    slots = []
    for cuisine, cfg in CUISINES.items():
        n_laksa = LAKSA_COUNTS.get(cuisine, 0)
        for index in range(cfg["count"]):
            slots.append((cuisine, index < n_laksa))
    assert len(slots) == 95, len(slots)
    rng.shuffle(slots)

    used_names = set(b["name"] for b in BASE)
    owners = list(OWNERS)
    rng.shuffle(owners)
    owner_cursor = 0

    for offset, (cuisine, laksa) in enumerate(slots):
        rid = "r%d" % (6 + offset)
        cfg = CUISINES[cuisine]
        menu = make_menu(rid, cuisine, cfg, laksa, rng)

        while True:
            owner = owners[owner_cursor % len(owners)]
            owner_cursor += 1
            if laksa:
                style = rng.choice(["{o}'s Laksa", "{o} Laksa House", "{o} Laksa & Kitchen"])
                if cuisine == "Peranakan":
                    style = rng.choice(["{o}'s Nyonya Laksa", "{o} Nyonya Laksa House", "{o} Peranakan Laksa"])
                name = style.format(o=owner)
            else:
                name = "%s %s" % (owner, rng.choice(cfg["suffix"]))
            if name not in used_names:
                used_names.add(name)
                break

        area = rng.choice(AREAS)
        main_items = [i for i in menu if i["category"] in ("Mains", "Noodles", "Rice", "Sets")]
        signature_pool = [i for i in main_items if "laksa" in i["tags"]] if laksa else main_items
        signature = (signature_pool or menu)[0]["name"]
        blurb = rng.choice(cfg["blurbs"]).format(sig=signature, area=area)
        if laksa:
            blurb = "Rich coconut curry laksa, simmered daily. " + blurb

        symbol = rng.choice(cfg["symbols"])
        color = PALETTE[rng.choice(cfg["colors"])]
        restaurants.append(dict(
            id=rid, name=name, cuisine=cuisine, rating=rng.randint(36, 49) / 10.0,
            deliveryMinutes=rng.randint(15, 45), deliveryFee=rng.randint(99, 499) / 100.0, isOpen=True,
            imageName=symbol, tags=restaurant_tags(cfg, menu, laksa, rng), description=blurb, area=area,
            reviewCount=int(20 + 2980 * (rng.random() ** 2)), priceLevel=rng.choice(cfg["price"]),
            colorHex=color, menu=menu,
        ))

    # About 8% closed: r4 plus 7 others. Laksa specialists stay open so recommendations always have candidates.
    candidates = [r for r in restaurants[5:] if "laksa" not in r["tags"]]
    for restaurant in rng.sample(candidates, 7):
        restaurant["isOpen"] = False

    restaurants.sort(key=lambda r: int(r["id"][1:]))
    return restaurants


def main():
    restaurants = build()
    with open(OUTPUT, "w", encoding="utf-8") as handle:
        json.dump(restaurants, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


if __name__ == "__main__":
    main()
