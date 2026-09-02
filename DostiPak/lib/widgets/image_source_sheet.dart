import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/widgets/svg_icon.dart';

class ImageSourceSheet extends StatelessWidget {
  // Constructor
  const ImageSourceSheet({required this.onImageSelected, super.key});

  // Callback function to return image file
  final Function(File?) onImageSelected;
  // ImagePicker instance (static so the class can keep its const constructor)
  static final ImagePicker picker = ImagePicker();

  Future<void> selectedImage(BuildContext context, File? image) async {
    // image_cropper removed: the picked image is returned uncropped
    onImageSelected(image);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return BottomSheet(
        onClosing: () {},
        builder: ((context) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [

            SizedBox(height: 10,),

            Container(
              padding: const EdgeInsets.all(18),
              width: 200,
              height: 5,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(300) ,color: Colors.grey,),
            ),

            SizedBox(height: 15,),


            Text(i18n.translate("media") , style: TextStyle(color: Theme.of(context).primaryColor , fontSize: 24),),
            SizedBox(height: 15,),


            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(i18n.translate("choose_your_image") , style: TextStyle(color: Colors.grey.withOpacity(0.7) , fontSize: 18),),
            ),
            SizedBox(height: 5,),


            /// SafeArea(top: false) keeps the Gallery / Camera buttons above
            /// the Android nav bar (3-button / gesture) on edge-to-edge.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[

                    /// Select image from gallery
                    ElevatedButton.icon(
                      icon: Icon(Icons.photo_size_select_actual_outlined, color: Colors.white, size: 28),
                      label: Text(i18n.translate("gallery"), style: TextStyle(fontSize: 20 , color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(400))
                      ),
                      onPressed: () async {

                        // Get image from device gallery
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );

                        if (pickedFile == null) return;
                        selectedImage(context, File(pickedFile.path));
                      },
                    ),

                    SizedBox(width: 25,),

                    /// Capture image from camera
                    OutlinedButton.icon(
                      // icon: SvgIcon("assets/icons/camera_icon.svg", width: 24, height: 24),
                      icon: Icon(Icons.camera, color: Theme.of(context).primaryColor, size: 28),
                      label: Text(i18n.translate("camera"), style: TextStyle(fontSize: 20 , color: Theme.of(context).primaryColor)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(400)),
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      onPressed: () async {
                        // Capture image from camera
                        final XFile? pickedFile = await picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (pickedFile == null) return;
                        selectedImage(context, File(pickedFile.path));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        )));
  }
}
