class Contact {
  int? id;
  String name;
  String contact;
  String address;

  Contact({
    this.id,
    required this.name,
    required this.contact,
    required this.address,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
      id: json['id'],
      name: json['name'],
      contact: json['contact'],
      address: json['address']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contact': contact,
    'address': address,
  };
}