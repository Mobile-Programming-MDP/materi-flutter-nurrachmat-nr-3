import 'package:cepu_app/screens/add_post_screen.dart';
import 'package:cepu_app/screens/sign_in_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //testSetUser();
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cepu App"),
        actions: [
          IconButton(
            onPressed: () {
              signOut();
            },
            icon: Icon(Icons.logout),
            tooltip: "Sign Out",
          ),
        ],
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              "Hallo ${FirebaseAuth.instance.currentUser?.displayName}",
            ),
          ),
          const Center(child: Text("You Have Been Signed In!")),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // void testSetUser() async {
  //   User? user = FirebaseAuth.instance.currentUser;

  //   if (user != null) {
  //     //await user.updateDisplayName("Nur Rachmat");
  //     await user.updateProfile(
  //       displayName: "Nur Rachmat",
  //       photoURL:
  //           "https://www.harapanrakyat.com/wp-content/uploads/2025/07/Kapten-Timnas-Indonesia-Jay-Idzes-Dilirik-5-Klub-Top-Eropa.jpg",
  //     );
  //     await user.reload();
  //   }
  // }
}
