class StoreLocation {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final String hours;

  const StoreLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.hours,
  });
}

const stores = [
  StoreLocation(
    id: 'central',
    name: 'GWEN Store Central',
    address: 'Jl. Sudirman No. 8, Jakarta',
    lat: -6.201,
    lng: 106.818,
    phone: '+62 21 555 0101',
    hours: 'Mon-Sun 10:00-21:00',
  ),
  StoreLocation(
    id: 'south',
    name: 'GWEN Store South',
    address: 'Jl. Fatmawati No. 21, Jakarta',
    lat: -6.206,
    lng: 106.814,
    phone: '+62 21 555 0102',
    hours: 'Mon-Sun 10:00-20:00',
  ),
];
