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
   bool _isSubmitting = false;
  bool _isGettingLocation = false;

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

   //4. Fungsi Widget tampil gambar
  Widget _buildImagePreview() {
    if (_base64Image == null) {
      return Container(
        height: 180,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade400),
        ),
        child: const Text('Belum ada gambar dipilih'),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        base64Decode(_base64Image!),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  //5. Fungsi Widget tampil lokasi
  Widget _buildLocationInfo() {
    if (_latitude == null || _longitude == null) {
      return const Text('Lokasi belum diambil');
    }

    return Text(
      'Lat: $_latitude\nLng: $_longitude',
      textAlign: TextAlign.center,
    );
  }

  //6. Fungsi submit Post
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
      appBar: AppBar(title: Text("Add new post")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSubmitting ? null : pickImageAndConvert,
              child: const Text('Pick Image'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isSubmitting ? null : _showCategorySelect,
              child: const Text('Select Category'),
            ),
            const SizedBox(height: 8),
            Text(
              _category ?? 'Belum memilih kategori',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                hintText: 'Masukkan deskripsi laporan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: (_isSubmitting || _isGettingLocation)
                  ? null
                  : _getLocation,
              child: Text(
                _isGettingLocation ? 'Mengambil Lokasi...' : 'Get Location',
              ),
            ),
            const SizedBox(height: 8),
            _buildLocationInfo(),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPost,
              child: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}