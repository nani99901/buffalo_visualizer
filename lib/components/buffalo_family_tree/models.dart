class Buffalo {
  int id;
  int age;
  bool mature;
  int? parentId;
  int generation;
  int birthYear;
  int acquisitionMonth;
  int unit;

  Buffalo({
    required this.id,
    required this.age,
    required this.mature,
    this.parentId,
    required this.generation,
    required this.birthYear,
    required this.acquisitionMonth,
    required this.unit,
  });
}

class YearlyData {
  int year;
  int totalBuffaloes;
  int producingBuffaloes;
  int liters = 0; // optional
  double revenue = 0;

  YearlyData({
    required this.year,
    required this.totalBuffaloes,
    required this.producingBuffaloes,
    this.liters = 0,
    this.revenue = 0,
  });
}
