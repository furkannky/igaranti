class PopularBrands {
  static const Map<String, List<String>> brandsByCategory = {
    'Elektronik': [
      'Apple', 'Samsung', 'Xiaomi', 'Huawei', 'Oppo', 'Vivo', 'Realme',
      'Sony', 'LG', 'Panasonic', 'Philips', 'Bose', 'JBL', 'Harman Kardon',
      'Dyson', 'iRobot', 'Roborock', 'Shark', 'Miele', 'Bosch', 'Siemens'
    ],
    'Mutfak': [
      'Beko', 'Arçelik', 'Vestel', 'Samsung', 'Bosch', 'Siemens', 'Miele',
      'Smeg', 'KitchenAid', 'Tefal', 'Arcelik', 'Fakir', 'Rowenta',
      'Braun', 'Moulinex', 'Kenwood', 'Delonghi', 'Nespresso', 'Krups'
    ],
    'Ev Gereçleri': [
      'Vestel', 'Beko', 'Arçelik', 'Samsung', 'LG', 'Sony', 'Philips',
      'Panasonic', 'Sharp', 'TCL', 'Hisense', 'Xiaomi', 'Dyson',
      'Electrolux', 'Hoover', 'Rowenta', 'Karcher', 'Bosch', 'Siemens'
    ],
    'Mobilya': [
      'İKEA', 'Koçtaş', 'Praktiker', 'Vivense', 'ENZA', 'Doğtaş', 'Kelebek',
      'Bellona', 'English Home', 'Masa', 'Derimod', 'Paşabahçe', 'Karaca',
      'Porland', 'Bambula', 'Lazzoni', 'Koleksiyon', 'Burger'
    ],
    'Diğer': [
      'Apple', 'Samsung', 'Xiaomi', 'Huawei', 'Fitbit', 'Garmin', 'Xiaomi',
      'JBL', 'Sony', 'Bose', 'Anker', 'Belkin', 'Logitech', 'Razer',
      'Corsair', 'TP-Link', 'Netgear', 'Asus', 'D-Link', 'Linksys'
    ],
  };

  static List<String> getBrandsForCategory(String category) {
    return brandsByCategory[category] ?? brandsByCategory['Diğer']!;
  }

  static List<String> getAllBrands() {
    Set<String> allBrands = {};
    for (var brands in brandsByCategory.values) {
      allBrands.addAll(brands);
    }
    return allBrands.toList()..sort();
  }
}
