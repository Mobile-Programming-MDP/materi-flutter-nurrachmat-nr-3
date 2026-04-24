import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:notes/models/note.dart';
import 'package:notes/services/note_service.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDialog extends StatefulWidget {
  final Note? note;

  const NoteDialog({super.key, this.note});

  @override
  State<NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<NoteDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  String? _base64Image;

  //1. Add Varibale and dependency 
  //flutter pub add geolocator
  //flutter pub add url_launcher
  String? _latitude;
  String? _longitude;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _descriptionController.text = widget.note!.description;
      _base64Image = widget.note!.imageBase64;
      _latitude = widget.note!.latitude;
      _longitude = widget.note!.longitude;
    }
  }

  Future<void> pickImageAndConvert() async {
    final ImagePicker picker = ImagePicker();
    
    // 1. Pick an image
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // 2. Read image as bytes
      final bytes = await image.readAsBytes();

      // 3. Encode bytes to Base64 string
      String base64String = base64Encode(bytes);
      setState(() {
        _base64Image = base64String;
      });

      print("Base64 String: $base64String");
    } else {
      print("No image selected.");
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

  //3. fungsi open GMAP
  Future<void> openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_latitude},${_longitude}',
    );
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membuka peta.")),
      );
    }
  }


  Future<void> _compressAndEncodeImage() async {
    if (_image == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _image!.path,
        quality: 50,
      );

      if (compressedImage == null) return;

      setState(() {
        _base64Image = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Gagal memproses gambar")));
      }
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.note == null ? 'Add Notes' : 'Update Notes'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Title: ', textAlign: TextAlign.start),
          TextField(controller: _titleController),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Description: '),
          ),
          TextField(controller: _descriptionController),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text('Image: '),
          ),
          Expanded(
            child: _base64Image != null
                ? Image.memory(
                    base64Decode(_base64Image!),
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Icon(
                      Icons.add_a_photo,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
          ),

          TextButton(
            //onPressed: _showImageSourceDialog,
            onPressed: pickImageAndConvert,
            child: const Text('Pick Image'),
          ),

          //4. Button Gel Location and Show Latitude and Longitude
          TextButton(
            onPressed: _getLocation,
            child: const Text('Get Current Location'),
          ),
          if (_latitude != null && _longitude != null)
            Text('Location: ($_latitude, $_longitude)'),
          //5. Button Open GMAP  
          if (_latitude != null && _longitude != null)
            TextButton(
              onPressed: openMap,
              child: const Text('Open in Maps'),
            ),  
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.note == null) {
              NoteService.addNote(
                Note(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  imageBase64: _base64Image,
                  latitude: _latitude,
                  longitude: _longitude,
                ),
              ).whenComplete(() {
                Navigator.of(context).pop();
              });
            } else {
              
              NoteService.updateNote(
                Note(
                  id: widget.note!.id,
                  title: _titleController.text,
                  description: _descriptionController.text,
                  createdAt: widget.note!.createdAt,
                  imageBase64: _base64Image,
                  latitude: _latitude,
                  longitude: _longitude,
                ),
              ).whenComplete(() => Navigator.of(context).pop());
            }
          },
          child: Text(widget.note == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
