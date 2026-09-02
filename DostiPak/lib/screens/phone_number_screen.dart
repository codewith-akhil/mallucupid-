import 'package:firebase_auth/firebase_auth.dart';
import 'package:rishtpak/constants/constants.dart';
import 'package:rishtpak/dialogs/progress_dialog.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/screens/home_screen.dart';
import 'package:rishtpak/screens/sign_up_screen.dart';
import 'package:rishtpak/widgets/default_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberScreen extends StatefulWidget {

  //New Vars
  bool isSecurePassword = true;


  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldkey = GlobalKey<ScaffoldState>();
  //New Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  //New Controllers
  late AppLocalizations _i18n;
  late ProgressDialog _pr;



  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context, isDismissible: false);

    return Scaffold(
          key: _scaffoldkey,
          appBar: AppBar(
            title: Text(_i18n.translate("phone_password")),
          ),
          body: SingleChildScrollView(
            // Bottom padding keeps the CONTINUE / sign-up / forget-password
            // controls reachable above the Android nav bar.
            padding: EdgeInsets.fromLTRB(20, 20, 20,
                MediaQuery.of(context).padding.bottom + 24),
            child: Column(
              children: <Widget>[

                ////////////////////////// * Image * //////////////////////////
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(Icons.email_outlined , color: Colors.white, size: 30,),
                ),
                SizedBox(height: 10),


                ////////////////////////// * Title * //////////////////////////
                Text(_i18n.translate("sign_in_with_email_password"), textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                SizedBox(height: 25),



                ////////////////////////// * Subtitle * //////////////////////////
                Text(
                    _i18n.translate("enter_your_email_password_and_we_will_send_verification_email"),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 22),

                /// Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[


                      ////////////////////////// * Phone Number (OLD) * //////////////////////////
                      // TextFormField(
                      //   controller: _numberController,
                      //   decoration: InputDecoration(
                      //       labelText: _i18n.translate("phone_number"),
                      //       hintText: _i18n.translate("enter_your_number"),
                      //       floatingLabelBehavior: FloatingLabelBehavior.always,
                      //       prefixIcon: Padding(
                      //         padding: const EdgeInsets.only(left: 8.0),
                      //         child: CountryCodePicker(
                      //             alignLeft: false,
                      //             initialSelection: _initialSelection,
                      //             onChanged: (country) {
                      //               /// Get country code
                      //               _phoneCode = country.dialCode!;
                      //             }),
                      //       )),
                      //   keyboardType: TextInputType.number,
                      //   inputFormatters: <TextInputFormatter>[
                      //     FilteringTextInputFormatter.allow(new RegExp("[0-9]"))
                      //   ],
                      //   validator: (number) {
                      //     // Basic validation
                      //     if (number == null) {
                      //       return _i18n
                      //           .translate("please_enter_your_phone_number");
                      //     }
                      //     return null;
                      //   },
                      // ),




                      ////////////////////////// * Email/Password (NEW) * //////////////////////////
                      AutofillGroup(
                        child: Column(
                          children: [

                            ////////////////////////// * Email (NEW) * //////////////////////////
                            TextFormField(
                              autofillHints: [AutofillHints.email],
                              controller: _emailController,
                              enableSuggestions: true,
                              readOnly: false,
                              autocorrect: true,
                              style: TextStyle(color: APP_TEXT_COLOR),
                              textInputAction: TextInputAction.next,
                              cursorColor: Theme.of(context).primaryColor,
                              decoration: InputDecoration(
                                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                                errorStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontStyle: FontStyle.italic , fontWeight: FontWeight.w200),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(300),
                                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                ),
                                  focusedBorder:  OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(300),
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                  ),
                                  enabledBorder:  OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(300),
                                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                  ),
                                  labelText: _i18n.translate("email"),
                                  hintText: _i18n.translate("enter_your_email"),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(Icons.email_outlined , color: Theme.of(context).primaryColor,)
                                  )
                              ),
                              keyboardType: TextInputType.emailAddress,
                              // inputFormatters: <TextInputFormatter>[
                              //   FilteringTextInputFormatter.allow(new RegExp("[0-9]"))
                              // ],
                              validator: (email) {
                                // Basic validation
                                if (email == null || email.isEmpty) {
                                  return _i18n.translate("please_enter_your_email");
                                }
                                else if (!validateEmail(email)){
                                  return _i18n.translate("invalid_email_address");
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20,),



                            ////////////////////////// * Password (NEW) * //////////////////////////
                            TextFormField(
                              autofillHints: [AutofillHints.password],
                              controller: _passwordController,
                              obscureText: widget.isSecurePassword,
                              autocorrect: true,
                              enableSuggestions: true,
                              readOnly: false,
                              textInputAction: TextInputAction.done,
                              cursorColor: Theme.of(context).primaryColor,
                              style: TextStyle(color: APP_TEXT_COLOR),
                              onEditingComplete: () => TextInput.finishAutofillContext(),
                              decoration: InputDecoration(
                                errorStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontStyle: FontStyle.italic , fontWeight: FontWeight.w200),
                                labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(300),
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                ),
                                focusedBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(300),
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                ),
                                enabledBorder:  OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(300),
                                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                                ),
                                labelText: _i18n.translate("password"),
                                hintText: _i18n.translate("enter_your_password"),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.vpn_key_outlined , color: Theme.of(context).primaryColor,)
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(widget.isSecurePassword ? Icons.visibility : Icons.visibility_off),
                                  color: Theme.of(context).primaryColor,
                                  highlightColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  hoverColor: Colors.transparent,
                                  onPressed: () {

                                    widget.isSecurePassword = !widget.isSecurePassword;
                                    setState(() {
                                    });


                                  },
                                ),

                              ),
                              keyboardType: TextInputType.text,
                              // inputFormatters: <TextInputFormatter>[
                              //   FilteringTextInputFormatter.allow(new RegExp("[0-9]"))
                              // ],
                              validator: (password) {
                                // Sign-in only needs a non-empty password:
                                // strength rules belong to sign-up, not here.
                                if (password == null || password.isEmpty) {
                                  return _i18n.translate("please_enter_your_password");
                                }
                                return null;
                              },
                            ),

                          ],
                        ),
                      ),
                      SizedBox(height: 8,),



                      ////////////////////////// * Button * //////////////////////////
                      SizedBox(height: 20),
                      SizedBox(
                        width: double.maxFinite,
                        child: DefaultButton(
                          child: Text(_i18n.translate("CONTINUE"), style: TextStyle(fontSize: 18)),
                          onPressed: () async {
                            /// Validate form
                            /// Sign in
                            _signIn(context);
                          },
                        ),
                      ),



                      ////////////////////////// * Button sign up * //////////////////////////
                      SizedBox(height: 12),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: 40,
                        child: Center(
                          child: DefaultButton(
                            width: 120,
                            height: 30,
                            child:  Text(
                                _i18n.translate('sign_up'),
                                style: TextStyle(
                                    color: Colors.white,
                                    // fontWeight: FontWeight.w400,
                                    fontSize: 12 ,
                                    letterSpacing: 2)
                            ),
                            onPressed: () async {
                              //Go to sign up
                              Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => SignUpScreen()));
                            },
                          ),
                        ),
                      ),



                      ////////////////////////// * Forget Password (NEW) * //////////////////////////
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.symmetric(vertical: 12.0 , horizontal: 18),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: (){

                                  // Send a real Firebase password reset email
                                  // (Firebase emails the reset link itself -
                                  // no SMTP / external service involved)
                                  _showForgotPasswordDialog();

                                },
                                child: Text(
                                  _i18n.translate("forget_password"),
                                  style: TextStyle(
                                    // decoration:  TextDecoration.underline,
                                    // decorationColor: Theme.of(context).primaryColor,
                                      color: Theme.of(context).primaryColor,
                                      // fontWeight: FontWeight.w400,
                                      fontSize: 12 ,
                                      // fontStyle: FontStyle.italic,
                                      letterSpacing: 2),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),


                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  /// Sign in with email + password.
  ///
  /// FIX (the "loading only" bug): every failure path now shows a friendly
  /// message and the progress dialog is ALWAYS dismissed in [finally].
  /// Previously only 'user-not-found' and 'wrong-password' were handled -
  /// any other FirebaseAuthException (invalid-credential, network, etc.)
  /// escaped the catch block, `ProgressDialog.hide()` never ran and the
  /// non-dismissible "Processing..." spinner stayed on screen forever.
  void _signIn(BuildContext context) async {

    // Validate inputs first (inline messages, no Firebase call yet)
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar(_i18n.translate("please_fill_data"));
      return;
    }
    if (!validateEmail(email)) {
      _showErrorSnackBar(_i18n.translate("invalid_email_address"));
      return;
    }

    // Show progress dialog
    _pr.show(_i18n.translate("processing"));

    try {
      // Sign in with Email And Password
      // (Firebase sends verification / password-reset emails itself -
      //  the app never needs SMTP or an external mail service)
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      debugPrint('sign in successfully: ${userCredential.user?.uid}');

      /// Auth user account: check the Firestore profile exists / is not
      /// blocked, then route. [onError] covers Firestore failures
      /// (offline, permission-denied) so loading can never hang here.
      await UserModel().authUserAccount(
          context: context,
          scaffoldkey: _scaffoldkey,
          homeScreen: () {
            /// Go to home screen
            Future(() {
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                  (route) => false);
            });
          },
          signUpScreen: () {
            /// Auth OK but no profile doc yet -> finish sign up
            Future(() {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => SignUpScreen()));
            });
          },
          onError: () {
            _showErrorSnackBar(_i18n.translate("no_internet_connection"));
          });
    }
    on FirebaseAuthException catch (e) {
      debugPrint('_signIn() -> FirebaseAuthException: ${e.code}');
      _showErrorSnackBar(_mapAuthError(e));
    }
    catch (e) {
      debugPrint('_signIn() -> unexpected error: $e');
      _showErrorSnackBar(_i18n.translate("error_generic"));
    }
    finally {
      // Guaranteed on EVERY path: success, auth error, network error
      _pr.hide();
    }
  }

  /// Map FirebaseAuthException codes to friendly, human messages.
  /// Shared by sign-in and the password-reset dialog.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential': // newest Firebase SDKs merge wrong-password
      case 'wrong-password':     // and user-not-found into invalid-credential
        return _i18n.translate("incorrect_email_or_password");
      case 'user-not-found':
        return _i18n.translate("no_account_found_with_this_email");
      case 'invalid-email':
        return _i18n.translate("invalid_email_address");
      case 'user-disabled':
        return _i18n.translate("account_disabled");
      case 'too-many-requests':
        return _i18n.translate("too_many_attempts");
      case 'network-request-failed':
        return _i18n.translate("no_internet_connection");
      default:
        return '${_i18n.translate("sign_in_failed")} (${e.code}). ${_i18n.translate("please_try_again")}';
    }
  }

  /// Themed error feedback (floating rose-charcoal SnackBarTheme,
  /// error background) via ScaffoldMessenger.
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: APP_ERROR_COLOR,
      content: Text(message, style: const TextStyle(color: Colors.white)),
    ));
  }

  /// Password reset: asks for the account email and makes Firebase send
  /// the reset link. Success -> themed snackbar. Failure -> mapped error.
  void _showForgotPasswordDialog() {
    final TextEditingController resetEmailController =
        TextEditingController(text: _emailController.text.trim());

    showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(_i18n.translate("reset_password_title")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_i18n.translate("reset_password_instructions")),
                SizedBox(height: 15),
                TextField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: _i18n.translate("email"),
                      hintText: _i18n.translate("enter_your_email")),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_i18n.translate("cancel"))),
              TextButton(
                  onPressed: () async {
                    final String email = resetEmailController.text.trim();
                    if (!validateEmail(email)) {
                      _showErrorSnackBar(
                          _i18n.translate("invalid_email_address"));
                      return;
                    }
                    try {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);
                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: APP_SUCCESS_COLOR,
                        content: Text(
                            '${_i18n.translate("password_reset_sent")} $email',
                            style:
                                const TextStyle(color: Colors.white)),
                      ));
                    }
                    on FirebaseAuthException catch (e) {
                      debugPrint(
                          'sendPasswordResetEmail() -> ${e.code}');
                      _showErrorSnackBar(_mapAuthError(e));
                    }
                    catch (e) {
                      debugPrint(
                          'sendPasswordResetEmail() -> unexpected: $e');
                      _showErrorSnackBar(
                          _i18n.translate("error_generic"));
                    }
                  },
                  child: Text(_i18n.translate("send_reset_link"))),
            ],
          );
        });
  }

  ///Validate email format
  bool validateEmail(String email){
    bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
    return emailValid;
  }
}
