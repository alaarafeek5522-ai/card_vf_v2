class CardModel {
  final String id;
  final String name;
  final String netCharge;
  final String units;
  final String duration;
  final String productId;
  final CardCategory category;
  final bool isPopular;
  final bool isNew;

  CardModel({
    required this.id,
    required this.name,
    required this.netCharge,
    required this.units,
    required this.duration,
    required this.productId,
    this.category = CardCategory.fakka,
    this.isPopular = false,
    this.isNew = false,
  });

  static List<CardModel> getAll() => [
    CardModel(id: '1',  name: 'فكة 2.5',  netCharge: '2.50',  units: '45 وحدة',         duration: 'يوم واحد',  productId: 'Fakka_2.5_Unite'),
    CardModel(id: '2',  name: 'فكة 3',    netCharge: '3.00',  units: '125 وحدة',        duration: 'يوم واحد',  productId: 'Fakka_3_Unite'),
    CardModel(id: '3',  name: 'فكة 4.25', netCharge: '4.25',  units: '190 وحدة',        duration: 'يوم واحد',  productId: 'Fakka_4.25_Unite'),
    CardModel(id: '4',  name: 'فكة 5',    netCharge: '5.00',  units: '225 وحدة',        duration: 'يوم واحد',  productId: 'Fakka_5_Unite',    isPopular: true),
    CardModel(id: '5',  name: 'فكة 7',    netCharge: '7.00',  units: '300 وحدة',        duration: '3 أيام',    productId: 'Fakka_7_Unite'),
    CardModel(id: '6',  name: 'فكة 9',    netCharge: '9.00',  units: '400 وحدة',        duration: '4 أيام',    productId: 'Fakka_9_Unite'),
    CardModel(id: '7',  name: 'فكة 10',   netCharge: '10.00', units: '300 وحدة',        duration: '2 أيام',    productId: 'Fakka_10_Unite',   isPopular: true),
    CardModel(id: '8',  name: 'فكة 10.5', netCharge: '10.50', units: '400 وحدة + 50MB', duration: '7 أيام',    productId: 'Fakka_10.5_Unite'),
    CardModel(id: '9',  name: 'فكة 12',   netCharge: '12.00', units: '425 وحدة',        duration: '6 أيام',    productId: 'Fakka_12_Unite'),
    CardModel(id: '10', name: 'فكة 13.5', netCharge: '13.50', units: '625 وحدة',        duration: '7 أيام',    productId: 'Fakka_13.5_Unite'),
    CardModel(id: '11', name: 'فكة 15',   netCharge: '15.00', units: '550 وحدة',        duration: '7 أيام',    productId: 'Fakka_15_Unite',    isPopular: true, isNew: true),
    CardModel(id: '12', name: 'فكة 15.5', netCharge: '15.50', units: '625 وحدة',        duration: '7 أيام',    productId: 'Fakka_15.5_Unite'),
    CardModel(id: '13', name: 'فكة 17.5', netCharge: '17.50', units: '650 وحدة',        duration: '10 أيام',   productId: 'Fakka_17.5_Unite'),
    CardModel(id: '14', name: 'فكة 20',   netCharge: '20.00', units: '750 وحدة',        duration: '10 أيام',   productId: 'Fakka_20_Unite',    isPopular: true),
    CardModel(id: 'm1', name: 'مارد 10 دقايق', netCharge: '10.00', units: '10 دقائق', duration: 'يوم واحد', productId: 'Mared_10_Minuts',  category: CardCategory.mared),
    CardModel(id: 'm2', name: 'مارد 10 فليكس', netCharge: '10.00', units: '10 فليكس',  duration: 'يوم واحد', productId: 'Mared_10_Flexs',   category: CardCategory.mared),
    CardModel(id: 'm3', name: 'مارد 10 سوشيال', netCharge: '10.00', units: '10 سوشيال', duration: 'يوم واحد', productId: 'Mared_10_Social',  category: CardCategory.mared),
  ];

  static List<CardModel> getFakka() => getAll().where((c) => c.category == CardCategory.fakka).toList();
  static List<CardModel> getMared() => getAll().where((c) => c.category == CardCategory.mared).toList();
  static List<CardModel> getPopular() => getAll().where((c) => c.isPopular).toList();
}

enum CardCategory { fakka, mared }
