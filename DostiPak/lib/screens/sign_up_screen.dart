import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:rishtpak/constants/constants.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/screens/home_screen.dart';
import 'package:rishtpak/widgets/image_source_sheet.dart';
import 'package:rishtpak/widgets/processing.dart';
import 'package:rishtpak/widgets/show_scaffold_msg.dart';
import 'package:rishtpak/widgets/svg_icon.dart';
import 'package:rishtpak/widgets/terms_of_service_row.dart';
import 'package:flutter/material.dart';
import 'package:rishtpak/widgets/default_button.dart';
import 'package:scoped_model/scoped_model.dart';

class SignUpScreen extends StatefulWidget {

  bool isSecurePassword = true;

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Variables
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// User Birthday info
  int _userBirthDay = 0;
  int _userBirthMonth = 0;
  int _userBirthYear = DateTime.now().year;
  // End
  DateTime _initialDateTime = DateTime.now();
  String? _birthday;
  File? _imageFile;
  bool _agreeTerms = false;
  String? _selectedGender;
  List<String> _genders = ['Male', 'Female'];
  late AppLocalizations _i18n;

  /// Set terms
  void _setAgreeTerms(bool value) {
    setState(() {
      _agreeTerms = value;
    });
  }

  /// Get image from camera / gallery
  void _getImage(BuildContext context) async {
    await showModalBottomSheet(
        context: context,
        builder: (context) => ImageSourceSheet(
              onImageSelected: (image) {
                if (image != null) {
                  setState(() {
                    _imageFile = image;
                  });
                  // close modal
                  Navigator.of(context).pop();
                }
              },
            ));
  }

  void _updateUserBithdayInfo(DateTime date) {
    setState(() {
      // Update the inicial date
      _initialDateTime = date;
      // Set for label
      _birthday = date.toString().split(' ')[0];
      // User birthday info
      _userBirthDay = date.day;
      _userBirthMonth = date.month;
      _userBirthYear = date.year;
    });
  }

  // Display the built-in Material date picker.
  Future<void> _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _initialDateTime,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );

    // Check picked date
    if (pickedDate != null) {
      // Get birthday info
      _updateUserBithdayInfo(pickedDate);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Initialization
    _i18n = AppLocalizations.of(context);
    _birthday = _i18n.translate("select_your_birthday");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_i18n.translate("sign_up")),
      ),
      body: ScopedModelDescendant<UserModel>(
          builder: (context, child, userModel) {
        /// Check loading status
        if (userModel.isLoading) return Processing();
        return SingleChildScrollView(
          // Bottom padding keeps the CTA reachable above the Android nav bar
          // (edge-to-edge: the body draws behind the 3-button / gesture nav).
          padding: EdgeInsets.fromLTRB(15, 15, 15,
              MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            children: <Widget>[
              Text(_i18n.translate("create_account"),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),

              /// Profile photo
              GestureDetector(
                child: Center(
                    child: _imageFile == null
                        ? CircleAvatar(
                            radius: 60,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: SvgIcon("assets/icons/camera_icon.svg",
                                width: 40, height: 40, color: Colors.white),
                          )
                        : CircleAvatar(
                            radius: 60,
                            backgroundImage: FileImage(_imageFile!),
                          )),
                onTap: () {
                  /// Get profile image
                  _getImage(context);
                },
              ),
              SizedBox(height: 10),
              Text(_i18n.translate("profile_photo"),
                  textAlign: TextAlign.center),

              SizedBox(height: 22),

              /// Form
              Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[


                    /// FullName field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                          labelText: _i18n.translate("fullname"),
                          hintText: _i18n.translate("enter_your_fullname"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgIcon("assets/icons/user_icon.svg"),
                          )),
                      validator: (name) {
                        // Basic validation
                        if (name?.isEmpty ?? false) {
                          return _i18n.translate("please_enter_your_fullname");
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),



                    /// User gender
                    DropdownButtonFormField<String>(
                      items: _genders.map((gender) {
                        return new DropdownMenuItem(
                          value: gender,
                          child: _i18n.translate("lang") != 'en'
                              ? Text(
                                  '${gender.toString()} - ${_i18n.translate(gender.toString().toLowerCase())}')
                              : Text(gender.toString()),
                        );
                      }).toList(),
                      hint: Text(_i18n.translate("select_gender")),
                      onChanged: (gender) {
                        setState(() {
                          _selectedGender = gender;
                        });
                      },
                      validator: (String? value) {
                        if (value == null) {
                          return _i18n.translate("please_select_your_gender");
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),





                    /// Birthday card
                    Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(color: Colors.grey[350] as Color)),
                        child: ListTile(
                          leading: SvgIcon("assets/icons/calendar_icon.svg"),
                          title: Text(_birthday!,
                              style: TextStyle(color: Colors.grey)),
                          trailing: Icon(Icons.arrow_drop_down),
                          onTap: () {
                            /// Select birthday
                            _showDatePicker();
                          },
                        )),
                    SizedBox(height: 20),



                    /// Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                          labelText: _i18n.translate("email"),
                          hintText: _i18n.translate("enter_your_email"),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          prefixIcon: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.email_outlined , color: Colors.grey,)
                          )
                      ),
                    ),
                    SizedBox(height: 20),



                    /// Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: widget.isSecurePassword,
                      decoration: InputDecoration(
                        labelText: _i18n.translate("password"),
                        hintText: _i18n.translate("enter_your_password"),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.vpn_key_outlined , color: Colors.grey)
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(widget.isSecurePassword ? Icons.visibility : Icons.visibility_off),
                          color: Colors.grey,
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
                    ),
                    SizedBox(height: 20),




                    /// Bio field
                    TextFormField(
                      controller: _bioController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: _i18n.translate("bio"),
                        hintText: _i18n.translate("please_write_your_bio"),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgIcon("assets/icons/info_icon.svg"),
                        ),
                      ),
                      validator: (bio) {
                        if (bio?.isEmpty ?? false) {
                          return _i18n.translate("please_write_your_bio");
                        }
                        return null;
                      },
                    ),



                    /// Agree terms
                    SizedBox(height: 5),
                    _agreePrivacy(),
                    SizedBox(height: 20),

                    /// Sign Up button
                    SizedBox(
                      width: double.maxFinite,
                      child: DefaultButton(
                        child: Text(_i18n.translate("CREATE_ACCOUNT"),
                            style: TextStyle(fontSize: 18)),
                        onPressed: () {
                          /// Sign up
                          _createAccount();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Handle Create account
  void _createAccount() async {
    /// check image file
    if (_imageFile == null) {
      // Show error message
      showScaffoldMessage(
          context: context,
          message: _i18n.translate("please_select_your_profile_photo"),
          bgcolor: APP_ERROR_COLOR);
      // validate terms
    } else if (!_agreeTerms) {
      // Show error message
      showScaffoldMessage(
          context: context,
          message: _i18n.translate("you_must_agree_to_our_privacy_policy"),
          bgcolor: APP_ERROR_COLOR);

      /// Validate form
    } else if (UserModel().calculateUserAge(_initialDateTime) < 18) {
      // Show error message
      showScaffoldMessage(
          context: context,
          duration: Duration(seconds: 7),
          message: _i18n.translate("only_18_years_old_and_above_are_allowed_to_create_an_account"),
          bgcolor: APP_ERROR_COLOR);
    }
    else if (!_formKey.currentState!.validate()) {

    }
    else if (!validateEmail(_emailController.text)){
      showScaffoldMessage(
          context: context,
          duration: Duration(seconds: 7),
          message: _i18n.translate("please_enter_your_email"),
          bgcolor: APP_ERROR_COLOR);
    }
    else if (!strongPassword(_passwordController.text)){
      showScaffoldMessage(
          context: context,
          duration: Duration(seconds: 7),
          message: _i18n.translate("password_needs_8"),
          bgcolor: APP_ERROR_COLOR);
    }
    else {
      /// Call all input onSaved method
      _formKey.currentState!.save();

      try {
        //Sign up Email And Password
        // (Firebase sends verification / reset emails itself -
        //  no SMTP or external mail service is needed in the app)
        debugPrint('sign up: creating firebase auth user...');
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text);
        debugPrint('sign up: firebase auth user created');

        /// Call sign up method.
        /// signUp() guarantees isLoading is reset and [onFail] fires on ANY
        /// failure (profile photo upload, Firestore write, GPS, token) -
        /// no silent hangs on the Processing() spinner.
        await UserModel().signUp(
            userWallet: 0.0,
            userOnline: true,
            userPhotoFile: _imageFile!,
            userFullName: _nameController.text.trim(),
            userGender: _selectedGender!,
            userBirthDay: _userBirthDay,
            userBirthMonth: _userBirthMonth,
            userBirthYear: _userBirthYear,
            userSchool: '',
            userJobTitle: '',
            userBio: _bioController.text.trim(),
            onSuccess: () async {
              debugPrint('sign up: account created successfully');
              // Show success message (themed snackbar) and go home
              showScaffoldMessage(
                  context: context,
                  message: _i18n.translate(
                      "your_account_has_been_created_successfully"),
                  bgcolor: APP_SUCCESS_COLOR);
              _goToHomeScreen();
            },
            onFail: (error) {
              // Debug error
              debugPrint('signUp() onFail: $error');
              // Show error message
              showScaffoldMessage(
                  context: context,
                  duration: Duration(seconds: 7),
                  message: _i18n.translate(
                      "an_error_occurred_while_creating_your_account"),
                  bgcolor: APP_ERROR_COLOR);
            });
      }
      on FirebaseAuthException catch (e) {
        debugPrint('_createAccount() -> FirebaseAuthException: ${e.code}');
        showScaffoldMessage(
            context: context,
            duration: Duration(seconds: 7),
            message: _mapSignUpError(e),
            bgcolor: APP_ERROR_COLOR);
      }
      catch (e) {
        debugPrint('_createAccount() -> unexpected error: $e');
        showScaffoldMessage(
            context: context,
            duration: Duration(seconds: 7),
            message: _i18n.translate("error_generic"),
            bgcolor: APP_ERROR_COLOR);
      }
    }
  }

  /// Map FirebaseAuthException codes from account creation to friendly,
  /// human messages.
  String _mapSignUpError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return _i18n.translate("account_exists_try_sign_in");
      case 'weak-password':
        return _i18n.translate("weak_password_min_six");
      case 'invalid-email':
        return _i18n.translate("invalid_email_address");
      case 'too-many-requests':
        return _i18n.translate("too_many_attempts");
      case 'network-request-failed':
        return _i18n.translate("no_internet_connection");
      default:
        return '${_i18n.translate("sign_up_failed")} (${e.code}). ${_i18n.translate("please_try_again")}';
    }
  }

  /// Handle Agree privacy policy
  ///
  /// Wrap (instead of a horizontal ScrollView) so "I agree with | Terms of
  /// service | Privacy policy" NEVER clips - it wraps to the next line on
  /// narrow screens instead of being cut off at the right edge.
  Widget _agreePrivacy() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 0,
      children: <Widget>[
        Checkbox(
            activeColor: Theme.of(context).primaryColor,
            value: _agreeTerms,
            onChanged: (value) {
              _setAgreeTerms(value!);
            }),
        GestureDetector(
            onTap: () => _setAgreeTerms(!_agreeTerms),
            child: Text(_i18n.translate("i_agree_with"),
                style: TextStyle(fontSize: 16))),
        // Terms of Service and Privacy Policy
        TermsOfServiceRow(color: APP_TEXT_COLOR),
      ],
    );
  }

  void _goToHomeScreen() {
    /// Go to home screen
    Future(() {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false);
    });
  }
}


///Validate if email   (NEW)
bool validateEmail(String email){
  bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  return emailValid;
}


///Validate if password   (NEW)
bool strongPassword(String password){
  if(
  (
      password.contains(RegExp(r"[a-z]")) || password.contains(RegExp(r"[A-Z]"))) &&
      password.contains(RegExp(r"[0-9]")) &&
      password.contains(RegExp(r'[!@#\$%^&*(),.?:{}[]|<>]')) &&
      password.length >= 8){

    return true;
  }
  else
    return false;
}
