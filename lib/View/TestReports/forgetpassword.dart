import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  TextEditingController emailController=TextEditingController();
  final auth=FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text("Forgot Password"),
      ),
      body:  Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextFormField(
          controller: emailController,
            decoration: InputDecoration(
              hintText: "Email",
            ),



        ),
            SizedBox(height: 40,),
            ElevatedButton(
              onPressed: () {
                auth.sendPasswordResetEmail(email: emailController.text.toString()).then((value) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('We have sent you an email to recover your password, please check your email'),
                    ),
                  );
                }).onError((error, stackTrace) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.toString()),
                    ),
                  );
                });
              },
              child: Text('Forgot'),
            )


          ],
        ),
      ),




    );
  }
}
