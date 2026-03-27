import 'package:firebase_database/firebase_database.dart';

class ShoppingService {
  final DatabaseReference _databaseReference = FirebaseDatabase.instance.ref().child("shopping_list");

  Stream<Map<String,String>> getShoppingList(){
    return _databaseReference.onValue.map((event) {
      final Map<String, String> items = {};
      DataSnapshot snapshot = event.snapshot;
      if(snapshot.value != null){
        Map<dynamic, dynamic> values = snapshot.value as Map<dynamic, dynamic>;
        values.forEach((key, value) {
          items[key] = value['name'] as String;
        });
      }
      return items;
    });
  }  

  void addShoppingItem(String item){
    _databaseReference.push().set({'name' : item});
  }

  Future<void> removeShoppingItem(String key) async{
    await _databaseReference.child(key).remove();
  }
}