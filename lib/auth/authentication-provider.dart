// import 'package:firebase_auth/firebase_auth.dart';

// class AuthenticationProvider {
//   final FirebaseAuth firebaseAuth;
//   //FirebaseAuth instance
//   AuthenticationProvider(this.firebaseAuth);
//   //Constuctor to initalize the FirebaseAuth instance

//   //Using Stream to listen to Authentication State
//   Stream<User> get authState => firebaseAuth.idTokenChanges();

//   //............RUDIMENTARY METHODS FOR AUTHENTICATION................

//   Future<String> signIn({String email, String password}) async {
//     try {
//       await firebaseAuth.signInWithEmailAndPassword(
//           email: email, password: password);
//        displayToastMessage(e!.message, context);
//     } on FirebaseAuthException catch (e) {
//       return e.message;
//     }
//   }

//    void displayToastMessage(String message, BuildContext context) {
//     Fluttertoast.showToast(msg: message);
//   }
// }
