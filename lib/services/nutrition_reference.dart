// Generated from USDA National Nutrient Database for Standard Reference,
// Release 28 (ABBREV.txt). Values per 100 g of the food as eaten: kcal,
// protein, carbs, fat. Plain foods carry no added cooking fat; the
// analysis lists that fat as its own item.

/// One reference food: per-100-g values and its USDA NDB number.
class ReferenceFood {
  final String ndb;
  final double kcal;
  final double protein;
  final double carbs;
  final double fats;

  const ReferenceFood(this.ndb, this.kcal, this.protein, this.carbs, this.fats);
}

const Map<String, ReferenceFood> referenceFoods = {
  // Chicken, broilers or fryers, breast, meat only, cooked, roasted
  'chicken_breast': ReferenceFood('05064', 165.0, 31.02, 0.0, 3.57),
  // Chicken, broilers or fryers, thigh, meat only, cooked, roasted
  'chicken_thigh': ReferenceFood('05098', 179.0, 24.76, 0.0, 8.15),
  // Chicken, broilers or fryers, meat and skin, cooked, roasted
  'chicken_with_skin': ReferenceFood('05009', 239.0, 27.3, 0.0, 13.6),
  // Chicken, broilers or fryers, breast, meat and skin, cooked, fried, batte
  'chicken_breaded_fried': ReferenceFood('05058', 260.0, 24.84, 8.99, 13.2),
  // Chicken, nuggets, white meat, precooked, frozen, not reheated
  'chicken_nuggets': ReferenceFood('22975', 261.0, 14.36, 16.24, 15.42),
  // Turkey, breast, from whole bird, meat only, roasted
  'turkey_breast': ReferenceFood('05220', 147.0, 30.13, 0.0, 2.08),
  // Beef, top sirloin, steak, separable lean and fat, trimmed to 1/8" fat, a
  'beef_steak': ReferenceFood('13930', 243.0, 26.96, 0.0, 14.23),
  // Beef, ground, 80% lean meat / 20% fat, crumbles, cooked, pan-browned
  'beef_ground_cooked': ReferenceFood('23575', 272.0, 27.0, 0.0, 17.36),
  // Beef, chuck, arm pot roast, separable lean and fat, trimmed to 1/8" fat,
  'beef_braised': ReferenceFood('13810', 302.0, 30.12, 0.0, 19.22),
  // Pork, fresh, loin, whole, separable lean and fat, cooked, roasted
  'pork_loin_roast': ReferenceFood('10023', 248.0, 27.09, 0.0, 14.65),
  // Pork, fresh, shoulder, whole, separable lean and fat, cooked, roasted
  'pork_shoulder_roast': ReferenceFood('10071', 292.0, 23.28, 0.0, 21.39),
  // Pork, fresh, loin, center loin (chops), bone-in, separable lean and fat,
  'pork_chop': ReferenceFood('10179', 238.0, 27.63, 0.0, 13.32),
  // Pork, cured, bacon, pre-sliced, cooked, pan-fried
  'bacon_cooked': ReferenceFood('10862', 468.0, 33.92, 1.7, 35.09),
  // Ham, sliced, regular (approximately 11% fat)
  'ham': ReferenceFood('07029', 163.0, 16.6, 3.83, 8.6),
  // Pork sausage, link/patty, cooked, pan-fried
  'sausage_pork': ReferenceFood('07064', 325.0, 18.53, 1.42, 27.25),
  // Bratwurst, pork, cooked
  'bratwurst': ReferenceFood('07013', 333.0, 13.72, 2.85, 29.18),
  // Frankfurter, beef, unheated
  'frankfurter': ReferenceFood('07022', 316.0, 11.16, 3.36, 28.3),
  // Salami, cooked, beef and pork
  'salami': ReferenceFood('07069', 336.0, 21.85, 2.4, 25.9),
  // Meatballs, frozen, Italian style
  'meatballs': ReferenceFood('07972', 286.0, 14.4, 8.06, 22.21),
  // Lamb, domestic, leg, whole (shank and sirloin), separable lean and fat,
  'lamb_roast': ReferenceFood('17012', 258.0, 25.55, 0.0, 16.48),
  // Lamb, ground, cooked, broiled
  'lamb_ground_cooked': ReferenceFood('17225', 283.0, 24.75, 0.0, 19.65),
  // Fish, salmon, Atlantic, farmed, cooked, dry heat
  'salmon': ReferenceFood('15237', 206.0, 22.1, 0.0, 12.35),
  // Fish, tuna, light, canned in water, drained solids
  'tuna_canned': ReferenceFood('15121', 86.0, 19.44, 0.0, 0.96),
  // Fish, cod, Atlantic, cooked, dry heat
  'white_fish': ReferenceFood('15016', 105.0, 22.83, 0.0, 0.86),
  // Restaurant, family style, fish fillet, battered or breaded, fried
  'fish_breaded_fried': ReferenceFood('36033', 219.0, 13.49, 16.89, 10.79),
  // Crustaceans, shrimp, cooked (not previously frozen)
  'shrimp': ReferenceFood('15271', 99.0, 23.98, 0.2, 0.28),
  // Egg, whole, cooked, hard-boiled
  'egg_boiled': ReferenceFood('01129', 155.0, 12.58, 1.12, 10.61),
  // Egg, whole, cooked, fried
  'egg_fried': ReferenceFood('01128', 196.0, 13.61, 0.83, 14.84),
  // Egg, whole, cooked, scrambled
  'egg_scrambled': ReferenceFood('01132', 149.0, 9.99, 1.61, 10.98),
  // Tofu, raw, firm, prepared with calcium sulfate
  'tofu': ReferenceFood('16426', 144.0, 17.27, 2.78, 8.72),
  // Rice, white, long-grain, regular, enriched, cooked
  'rice_white_cooked': ReferenceFood('20045', 130.0, 2.69, 28.17, 0.28),
  // Rice, brown, long-grain, cooked
  'rice_brown_cooked': ReferenceFood('20037', 123.0, 2.74, 25.58, 0.97),
  // Restaurant, Chinese, fried rice, without meat
  'fried_rice': ReferenceFood('36602', 174.0, 4.05, 32.79, 2.96),
  // Pasta, cooked, enriched, without added salt
  'pasta_cooked': ReferenceFood('20121', 158.0, 5.8, 30.86, 0.93),
  // Noodles, egg, enriched, cooked
  'egg_noodles_cooked': ReferenceFood('20110', 138.0, 4.54, 25.16, 2.07),
  // Rice noodles, cooked
  'rice_noodles_cooked': ReferenceFood('20134', 108.0, 1.79, 24.01, 0.2),
  // Couscous, cooked
  'couscous_cooked': ReferenceFood('20029', 112.0, 3.79, 23.22, 0.16),
  // Quinoa, cooked
  'quinoa_cooked': ReferenceFood('20137', 120.0, 4.4, 21.3, 1.92),
  // Bulgur, cooked
  'bulgur_cooked': ReferenceFood('20013', 83.0, 3.08, 18.58, 0.24),
  // Cereals, oats, regular and quick, unenriched, cooked with water (include
  'porridge_oats_water': ReferenceFood('08121', 71.0, 2.54, 12.0, 1.52),
  // Potatoes, boiled, cooked without skin, flesh, without salt
  'potato_boiled': ReferenceFood('11367', 86.0, 1.71, 20.01, 0.1),
  // Potatoes, baked, flesh and skin, without salt
  'potato_baked': ReferenceFood('11674', 93.0, 2.5, 21.15, 0.13),
  // Potatoes, mashed, home-prepared, whole milk and butter added
  'potato_mashed': ReferenceFood('11934', 113.0, 1.86, 16.81, 4.22),
  // Potatoes, french fried, all types, salt added in processing, frozen, hom
  'french_fries': ReferenceFood('11403', 158.0, 2.75, 25.55, 5.48),
  // Sweet potato, cooked, baked in skin, flesh, without salt
  'sweet_potato': ReferenceFood('11508', 90.0, 2.01, 20.71, 0.15),
  // Bread, white, commercially prepared (includes soft bread crumbs)
  'bread_white': ReferenceFood('18069', 266.0, 8.85, 49.42, 3.33),
  // Bread, whole-wheat, commercially prepared
  'bread_wholegrain': ReferenceFood('18075', 252.0, 12.45, 42.71, 3.5),
  // Bread, rye
  'bread_rye': ReferenceFood('18060', 259.0, 8.5, 48.3, 3.3),
  // Rolls, hamburger or hotdog, plain
  'bread_roll': ReferenceFood('18350', 279.0, 9.77, 50.12, 3.91),
  // Pretzels, soft
  'pretzel_soft': ReferenceFood('43109', 338.0, 8.2, 69.39, 3.1),
  // Tortillas, ready-to-bake or -fry, flour, refrigerated
  'tortilla_flour': ReferenceFood('18364', 306.0, 8.2, 49.38, 7.99),
  // Cereals ready-to-eat, granola, homemade
  'granola': ReferenceFood('08037', 489.0, 13.67, 53.88, 24.31),
  // Beans, kidney, all types, mature seeds, cooked, boiled, without salt
  'beans_cooked': ReferenceFood('16028', 127.0, 8.67, 22.8, 0.5),
  // Chickpeas (garbanzo beans, bengal gram), mature seeds, cooked, boiled, w
  'chickpeas_cooked': ReferenceFood('16057', 164.0, 8.86, 27.42, 2.59),
  // Lentils, mature seeds, cooked, boiled, without salt
  'lentils_cooked': ReferenceFood('16070', 116.0, 9.02, 20.13, 0.38),
  // Hummus, commercial
  'hummus': ReferenceFood('16158', 166.0, 7.9, 14.29, 9.6),
  // Falafel, home-prepared
  'falafel': ReferenceFood('16138', 333.0, 13.31, 31.84, 17.8),
  // Broccoli, cooked, boiled, drained, without salt
  'broccoli': ReferenceFood('11091', 35.0, 2.38, 7.18, 0.41),
  // Cauliflower, cooked, boiled, drained, without salt
  'cauliflower': ReferenceFood('11136', 23.0, 1.84, 4.11, 0.45),
  // Carrots, cooked, boiled, drained, without salt
  'carrot': ReferenceFood('11125', 35.0, 0.76, 8.22, 0.18),
  // Beans, snap, green, cooked, boiled, drained, without salt
  'green_beans': ReferenceFood('11053', 35.0, 1.89, 7.88, 0.28),
  // Brussels sprouts, cooked, boiled, drained, without salt
  'brussels_sprouts': ReferenceFood('11099', 36.0, 2.55, 7.1, 0.5),
  // Spinach, cooked, boiled, drained, without salt
  'spinach_cooked': ReferenceFood('11458', 23.0, 2.97, 3.75, 0.26),
  // Spinach, raw
  'spinach_raw': ReferenceFood('11457', 23.0, 2.86, 3.63, 0.39),
  // Squash, summer, zucchini, includes skin, cooked, boiled, drained, withou
  'zucchini': ReferenceFood('11478', 15.0, 1.14, 2.69, 0.36),
  // Eggplant, cooked, boiled, drained, without salt
  'eggplant': ReferenceFood('11210', 35.0, 0.83, 8.73, 0.23),
  // Peppers, sweet, red, raw
  'bell_pepper': ReferenceFood('11821', 31.0, 0.99, 6.03, 0.3),
  // Mushrooms, white, cooked, boiled, drained, without salt
  'mushrooms': ReferenceFood('11261', 28.0, 2.17, 5.29, 0.47),
  // Onions, raw
  'onion': ReferenceFood('11282', 40.0, 1.1, 9.34, 0.1),
  // Peas, green, frozen, cooked, boiled, drained, without salt
  'peas': ReferenceFood('11313', 78.0, 5.15, 14.26, 0.27),
  // Corn, sweet, yellow, cooked, boiled, drained, without salt
  'corn': ReferenceFood('11168', 96.0, 3.41, 20.98, 1.5),
  // Tomatoes, red, ripe, raw, year round average
  'tomato': ReferenceFood('11529', 18.0, 0.88, 3.89, 0.2),
  // Cucumber, with peel, raw
  'cucumber': ReferenceFood('11205', 15.0, 0.65, 3.63, 0.11),
  // Lettuce, green leaf, raw
  'lettuce_greens': ReferenceFood('11253', 15.0, 1.36, 2.87, 0.15),
  // Cabbage, raw
  'cabbage': ReferenceFood('11109', 25.0, 1.28, 5.8, 0.1),
  // Cabbage, red, cooked, boiled, drained, without salt
  'red_cabbage_cooked': ReferenceFood('11113', 29.0, 1.51, 6.94, 0.09),
  // Sauerkraut, canned, solids and liquids
  'sauerkraut': ReferenceFood('11439', 19.0, 0.91, 4.28, 0.14),
  // Asparagus, cooked, boiled, drained
  'asparagus': ReferenceFood('11012', 22.0, 2.4, 4.11, 0.22),
  // Avocados, raw, all commercial varieties
  'avocado': ReferenceFood('09037', 160.0, 2.0, 8.53, 14.66),
  // Olives, ripe, canned (small-extra large)
  'olives': ReferenceFood('09193', 115.0, 0.84, 6.26, 10.68),
  // Apples, raw, with skin
  'apple': ReferenceFood('09003', 52.0, 0.26, 13.81, 0.17),
  // Bananas, raw
  'banana': ReferenceFood('09040', 89.0, 1.09, 22.84, 0.33),
  // Oranges, raw, all commercial varieties
  'orange': ReferenceFood('09200', 47.0, 0.94, 11.75, 0.12),
  // Blueberries, raw
  'blueberries': ReferenceFood('09050', 57.0, 0.74, 14.49, 0.33),
  // Strawberries, raw
  'strawberries': ReferenceFood('09316', 32.0, 0.67, 7.68, 0.3),
  // Grapes, red or green (European type, such as Thompson seedless), raw
  'grapes': ReferenceFood('09132', 69.0, 0.72, 18.1, 0.16),
  // Mangos, raw
  'mango': ReferenceFood('09176', 60.0, 0.82, 14.98, 0.38),
  // Cheese, cheddar
  'cheese_hard': ReferenceFood('01009', 404.0, 22.87, 3.09, 33.31),
  // Cheese, mozzarella, whole milk
  'mozzarella': ReferenceFood('01026', 300.0, 22.17, 2.19, 22.35),
  // Cheese, parmesan, grated
  'parmesan': ReferenceFood('01032', 420.0, 28.42, 13.91, 27.84),
  // Cheese, feta
  'feta': ReferenceFood('01019', 264.0, 14.21, 4.09, 21.28),
  // Cheese, cream
  'cream_cheese': ReferenceFood('01017', 350.0, 6.15, 5.52, 34.44),
  // Cheese, cottage, creamed, large or small curd
  'cottage_cheese': ReferenceFood('01012', 98.0, 11.12, 3.38, 4.3),
  // Yogurt, plain, whole milk, 8 grams protein per 8 ounce
  'yogurt_plain': ReferenceFood('01116', 61.0, 3.47, 4.66, 3.25),
  // Yogurt, Greek, plain, nonfat
  'greek_yogurt_nonfat': ReferenceFood('01256', 59.0, 10.19, 3.6, 0.39),
  // Milk, whole, 3.25% milkfat, with added vitamin D
  'milk_whole': ReferenceFood('01077', 61.0, 3.15, 4.8, 3.25),
  // Milk, reduced fat, fluid, 2% milkfat, with added vitamin A and vitamin D
  'milk_reduced_fat': ReferenceFood('01079', 50.0, 3.3, 4.8, 1.98),
  // Cream, fluid, heavy whipping
  'cream_heavy': ReferenceFood('01053', 340.0, 2.84, 2.74, 36.08),
  // Cream, sour, cultured
  'sour_cream': ReferenceFood('01056', 198.0, 2.44, 4.63, 19.35),
  // Butter, salted
  'butter': ReferenceFood('01001', 717.0, 0.85, 0.06, 81.11),
  // Oil, olive, salad or cooking
  'oil': ReferenceFood('04053', 884.0, 0.0, 0.0, 100.0),
  // Salad dressing, mayonnaise, regular
  'mayonnaise': ReferenceFood('04025', 680.0, 0.96, 0.57, 74.85),
  // Salad dressing, italian dressing, commercial, regular
  'vinaigrette': ReferenceFood('04114', 240.0, 0.41, 12.12, 21.12),
  // Salad dressing, ranch dressing, regular
  'ranch_dressing': ReferenceFood('04639', 430.0, 1.32, 5.9, 44.54),
  // Salad dressing, caesar dressing, regular
  'caesar_dressing': ReferenceFood('43015', 542.0, 2.17, 3.3, 57.85),
  // Catsup
  'ketchup': ReferenceFood('11935', 101.0, 1.04, 27.4, 0.1),
  // Mustard, prepared, yellow
  'mustard': ReferenceFood('02046', 60.0, 3.74, 5.83, 3.34),
  // Sauce, pesto, ready-to-serve, refrigerated
  'pesto': ReferenceFood('06626', 418.0, 9.83, 10.09, 37.6),
  // Sauce, pasta, spaghetti/marinara, ready-to-serve
  'tomato_sauce': ReferenceFood('06931', 50.0, 1.39, 7.43, 1.61),
  // Gravy, beef, canned, ready-to-serve
  'gravy': ReferenceFood('06116', 53.0, 3.75, 4.81, 2.36),
  // Soy sauce made from soy (tamari)
  'soy_sauce': ReferenceFood('16124', 60.0, 10.51, 5.57, 0.1),
  // Nuts, mixed nuts, dry roasted, with peanuts, without salt added
  'mixed_nuts': ReferenceFood('12135', 607.0, 19.5, 22.42, 53.5),
  // Nuts, walnuts, english
  'walnuts': ReferenceFood('12155', 654.0, 15.23, 13.71, 65.21),
  // Nuts, almonds
  'almonds': ReferenceFood('12061', 579.0, 21.15, 21.55, 49.93),
  // Peanut butter, smooth style, without salt
  'peanut_butter': ReferenceFood('16398', 598.0, 22.21, 22.31, 51.36),
  // Seeds, sunflower seed kernels, dried
  'sunflower_seeds': ReferenceFood('12036', 584.0, 20.78, 20.0, 51.46),
  // Honey
  'honey': ReferenceFood('19296', 304.0, 0.3, 82.4, 0.0),
  // Jams and preserves
  'jam': ReferenceFood('19297', 278.0, 0.37, 68.86, 0.07),
  // Sugars, granulated
  'sugar': ReferenceFood('19335', 387.0, 0.0, 99.98, 0.0),
  // Chocolate, dark, 70-85% cacao solids
  'dark_chocolate': ReferenceFood('19904', 598.0, 7.79, 45.9, 42.63),
  // Chocolate-flavored hazelnut spread
  'hazelnut_spread': ReferenceFood('19125', 541.0, 5.41, 62.16, 29.73),
  // Pizza, cheese topping, regular crust, frozen, cooked
  'pizza_cheese': ReferenceFood('21224', 268.0, 10.36, 29.02, 12.28),
  // Pizza, meat and vegetable topping, regular crust, frozen, cooked
  'pizza_meat_vegetable': ReferenceFood('21226', 276.0, 11.28, 25.14, 14.43),
  // Lasagna with meat & sauce, frozen entree
  'lasagna_meat': ReferenceFood('22916', 124.0, 6.63, 14.39, 4.42),
  // Fast foods, hamburger; single, regular patty; plain
  'hamburger': ReferenceFood('21107', 297.0, 16.52, 31.5, 12.01),
  // Fast foods, burrito, with beans and beef
  'burrito_beans_beef': ReferenceFood('21063', 191.0, 11.52, 19.52, 7.47),
  // Croissants, butter
  'croissant': ReferenceFood('18239', 406.0, 8.2, 45.8, 21.0),
  // Cake, pound, commercially prepared, butter (includes fresh and frozen)
  'pound_cake': ReferenceFood('18120', 353.0, 5.0, 53.64, 13.96),
  // Cookies, brownies, commercially prepared
  'brownie': ReferenceFood('18151', 405.0, 4.8, 63.9, 16.3),
  // Cookies, chocolate chip, commercially prepared, regular, higher fat, enr
  'cookie_chocolate_chip': ReferenceFood('18159', 492.0, 5.1, 65.36, 24.72),
  // Ice creams, vanilla
  'ice_cream_vanilla': ReferenceFood('19095', 207.0, 3.5, 23.6, 11.0),
  // Pancakes, plain, prepared from recipe
  'pancake': ReferenceFood('18293', 227.0, 6.4, 28.3, 9.7),
  // Waffles, plain, prepared from recipe
  'waffle': ReferenceFood('18367', 291.0, 7.9, 32.9, 14.1),
  // Soup, chunky vegetable, canned, ready-to-serve
  'vegetable_soup': ReferenceFood('06067', 39.0, 1.14, 7.9, 0.36),
  // Alcoholic beverage, beer, regular, all
  'beer': ReferenceFood('14003', 43.0, 0.46, 3.55, 0.0),
  // Alcoholic beverage, wine, table, red
  'wine_red': ReferenceFood('14096', 85.0, 0.07, 2.61, 0.0),
  // Orange juice, raw
  'orange_juice': ReferenceFood('09206', 45.0, 0.7, 10.4, 0.2),
};
