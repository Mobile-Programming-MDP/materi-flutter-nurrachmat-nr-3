import 'dart:convert';
import 'dart:io';

import 'package:cepu_app/models/post.dart';
import 'package:cepu_app/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _base64Image;
  String? _latitude;
  String? _longitude;
  List<String> get categories {
    return [
      'Jalan Rusak',
      'Lampu Jalan Mati',
      'Lawan Arah',
      'Merokok di Jalan',
      'Tidak Pakai Helm'
    ];
  }
  String? _category;

  //1.Fungsi pick, compress and convert Image
  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final compressedImage = await FlutterImageCompress.compressWithList(
        bytes,
        quality: 50,
      );
      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } 
  }
  
  //2. Fungsi Get Geo Location
  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Layanan lokasi dinonaktifkan.")),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Izin lokasi ditolak.")),
          );
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      debugPrint('Failed to retrieve location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengambil lokasi.")),
      );
      setState(() {
        _latitude = null;
        _longitude = null;
      });
    }
  }

  //3. Fungsi tampil pilihan kategori
  void _showCategorySelect(){
    showModalBottomSheet(
      context: context, 
      builder: (BuildContext context){
        return ListView(
          shrinkWrap: true,
          children: 
            categories.map((cat) {
              return ListTile(
                title: Text(cat),
                onTap: (){
                  setState(() {
                    _category = cat;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
        );
      }
    );
  }

  //4. Fungsi submit Post
  Future<void> _submitPost() async {
    if(_base64Image == null || _descriptionController.text.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Pilih gambar dan masukkan deskripsi")),
        );
    }
    //ambil user id dan full name dari firebaseauth
    final userId = FirebaseAuth.instance.currentUser?.uid; 
    final fullName = FirebaseAuth.instance.currentUser?.displayName; 
    try{
      _getLocation();
      PostService.addPost(
        Post(
          image: _base64Image,
          description: _descriptionController.text,
          category: _category,
          latitude: _latitude,
          longitude: _longitude,
          userId: userId,
          fullName: fullName,
        )
      ).whenComplete((){
        Navigator.of(context).pop();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Posting berhasil disimpan")),
      );
    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Posting gagal disimpan : $e")),
      );  
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add new post"),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextButton(
              //onPressed: _showImageSourceDialog,
              onPressed: pickImageAndConvert,
              child: const Text('Pick Image'),
            ),
            SizedBox(height: 16,),
            TextButton(
              //onPressed: _showImageSourceDialog,
              onPressed: _showCategorySelect,
              child: const Text('Select Category'),
            ),
            Text(_category!),
            // GestureDetector(
            //   onTap: _showCategorySelect,
            //   child: Chip(
            //     label: Row(
            //       children: [
            //         Text(_category!),
            //         Icon(Icons.edit, size: 16,)
            //       ],
            //     )
            //   ),
            // )
            ElevatedButton(
              onPressed: _submitPost, 
              child: Text("Submit")
              )
          ],
        ),
      ),
    );
  }
}