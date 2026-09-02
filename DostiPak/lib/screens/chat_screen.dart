import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rishtpak/api/likes_api.dart';
import 'package:rishtpak/api/matches_api.dart';
import 'package:rishtpak/api/messages_api.dart';
import 'package:rishtpak/api/notifications_api.dart';
import 'package:rishtpak/constants/constants.dart';
import 'package:rishtpak/datas/user.dart';
import 'package:rishtpak/dialogs/common_dialogs.dart';
import 'package:rishtpak/dialogs/progress_dialog.dart';
import 'package:rishtpak/dialogs/vip_dialog.dart';
import 'package:rishtpak/helpers/app_localizations.dart';
import 'package:rishtpak/models/user_model.dart';
import 'package:rishtpak/screens/profile_screen.dart';
import 'package:rishtpak/widgets/sticker_source_sheet.dart';
import 'package:rishtpak/widgets/chat_message.dart';
import 'package:rishtpak/widgets/git_source_sheet.dart';
import 'package:rishtpak/widgets/image_source_sheet.dart';
import 'package:rishtpak/widgets/my_circular_progress.dart';
import 'package:rishtpak/widgets/svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;


class ChatScreen extends StatefulWidget {
  /// Get user object
  final User user;

  const ChatScreen({required this.user, super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  // Variables
  //NEW
  bool _isVisibleTyping = false;
  bool _iAmWriting = false;
  double _opacityTyping = 0.0;

  bool isRecord = false;
  String recordFilePath = '';
  bool isOnline = true;

  // Expandable media buttons state
  bool _mediaOpen = false;

  // Native voice recorder (AAC-LC / .m4a) via MethodChannel.
  // Android implementation: MainActivity.kt (MediaRecorder based)
  static const MethodChannel _voiceRecorderChannel =
      MethodChannel('mallucupid/voice_recorder');

  Timer? _typingTimer;
  //NEW

  final _textController = TextEditingController();
  final _messagesController = ScrollController();
  final _messagesApi = MessagesApi();
  final _matchesApi = MatchesApi();
  final _likesApi = LikesApi();
  final _notificationsApi = NotificationsApi();
  late Stream<QuerySnapshot> _messages;
  bool _isComposing = false;
  late AppLocalizations _i18n;
  late ProgressDialog _pr;

  void _scrollMessageList() {
    /// Scroll to button
    _messagesController.animateTo(0.0,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  }

  /// Get image from camera / gallery
  Future<void> _getImage() async {
    await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20) ,  topRight: Radius.circular(20))
        ),
        builder: (context) => ImageSourceSheet(
              onImageSelected: (image) async {
                if (image != null) {
                  await _sendMessage(type: 'image', imgFile: image);
                  // close modal
                  Navigator.of(context).pop();
                }
              },
            ));
  }

  /// Get gif from sheet
  Future<void> _getGifs() async{
    await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20) ,  topRight: Radius.circular(20))
        ),
        builder: (context) => GifSourceSheet(
          onGifSelected: (urlPath) async {
            if (urlPath != null) {
              await _sendMessage(type: 'gif', urlGifPath: urlPath);
              // close modal
              Navigator.of(context).pop();
            }
          },
        ));
  }

  /// Get stickers from sheet
  Future<void> _getStickers() async {
    await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20) ,  topRight: Radius.circular(20))
        ),
        builder: (context) => StickerSourceSheet(
          onStickerSelected: (urlPath) async {
            if (urlPath != null) {
              await _sendMessage(type: 'sticker', urlStickerPath: urlPath);
              // close modal
              Navigator.of(context).pop();
            }
          },
        ));
  }

  // Send message
  Future<void> _sendMessage({required String type, String? text, File? imgFile , String urlAudioPath = '' , String urlGifPath = '' , String urlStickerPath = ''}) async {
    String textMsg = '';
    String imageUrl = '';

    // Check message type
    switch (type) {
      case 'text': {
        textMsg = text!;
        break;
      }

      case 'image': {
        // Show processing dialog
        _pr.show(_i18n.translate("sending"));

        /// Upload image file
        imageUrl = await UserModel().uploadFile(
            file: imgFile!,
            path: 'uploads/messages',
            userId: UserModel().user.userId);

        _pr.hide();
        break;
      }

      case 'audio': {
        // is uploaded already
        break;
      }

      case 'gif': {
        // is uploaded already
        break;
      }

      case 'sticker':
        // is uploaded already
        break;
    }

    /// Save message for current user
    await _messagesApi.saveMessage(
        urlAudioPath: urlAudioPath,
        urlGifPath: urlGifPath,
        urlStickerPath: urlStickerPath,
        type: type,
        fromUserId: UserModel().user.userId,
        senderId: UserModel().user.userId,
        receiverId: widget.user.userId,
        userPhotoLink: widget.user.userProfilePhoto, // other user photo
        userFullName: widget.user.userFullname, // other user ful name
        textMsg: textMsg,
        imgLink: imageUrl,
        isRead: true);


    /// Save copy message for receiver
    await _messagesApi.saveMessage(
        urlAudioPath: urlAudioPath,
        urlGifPath: urlGifPath,
        urlStickerPath: urlStickerPath,
        type: type,
        fromUserId: UserModel().user.userId,
        senderId: widget.user.userId,
        receiverId: UserModel().user.userId,
        userPhotoLink: UserModel().user.userProfilePhoto, // current user photo
        userFullName: UserModel().user.userFullname, // current user ful name
        textMsg: textMsg,
        imgLink: imageUrl,
        isRead: false);




    /// (NEW) Update user's wallet
    UserModel().getUser(UserModel().user.userId).then((snapshot) {

      Map<String,dynamic> data =  snapshot.data()! as Map<String, dynamic>;

      if(UserModel().user.userGender != "affiliate"){
        //Male - Female
        type == "text" ?
        data[USER_WALLET] = data[USER_WALLET] - 1
        :
        data[USER_WALLET] = data[USER_WALLET] - 10;
      }
      else {

        print('user is affiliate , do not need to change his wallet');

        // type == "text" ?
        // data[USER_WALLET] = data[USER_WALLET] + 1
        //     :
        // data[USER_WALLET] = data[USER_WALLET] + 10;
      }



      FirebaseFirestore.instance
          .collection(C_USERS)
          .doc(UserModel().user.userId)
          .update(data).then((value){

            print('user\'s wallets has changed , now change affiliate user\'s wallet');
            if(widget.user.userGender == "affiliate"){

              UserModel().getUser(widget.user.userId).then((snap){

                Map<String,dynamic> dataAffiliate =  snap.data()! as Map<String, dynamic>;

                type == "text"
                    ?
                dataAffiliate[USER_WALLET] = dataAffiliate[USER_WALLET] + 1
                    :
                (type == "gif" || type == "sticker")
                    ?
                dataAffiliate[USER_WALLET] = dataAffiliate[USER_WALLET]
                    :
                dataAffiliate[USER_WALLET] = dataAffiliate[USER_WALLET] + 6;


                //Update data
                FirebaseFirestore.instance
                    .collection(C_USERS)
                    .doc(widget.user.userId)
                    .update(dataAffiliate).then((value) => print('user\'s affiliated is updated in his wallet !'));


              });

            }
            else {
              print('receiver user is not affiliate , so you do not need to change any thing');
            }
      });

    });


    /// Send push notification
    await _notificationsApi.sendPushNotification(
        nTitle: UserModel().user.userFullname.toString(),   //APP_NAME
        nBody: '${UserModel().user.userFullname}, '
            '${_i18n.translate("sent_a_message_to_you")}',
        nType: 'message',
        nSenderId: UserModel().user.userId,
        nUserDeviceToken: widget.user.userDeviceToken);
  }



  @override
  void initState() {
    super.initState();
    _messages = _messagesApi.getMessages(widget.user.userId);


    //Typing Check (from friend)
    FirebaseFirestore.instance
        .collection(C_USERS)
        .doc(widget.user.userId)
        .snapshots().listen((snap) {

          Map<String , dynamic> friend = snap.data()![USER_TYPING];
          bool isTyping = friend[UserModel().user.userId]!;

          if(isTyping){
            if(!_isVisibleTyping){
              _isVisibleTyping = true;
              _opacityTyping = 1.0;
              setState(() {});
            }
          }
          else {
            if(_isVisibleTyping){
              _isVisibleTyping = false;
              _opacityTyping = 0.0;
              setState(() {});
            }
          }

    });


    // online/offline
    FirebaseFirestore.instance
        .collection(C_USERS)
        .doc(widget.user.userId)
        .snapshots().listen((snapshot) {


      Map<String,dynamic> data =  snapshot.data()! as Map<String, dynamic>;

      isOnline =  data[USER_ONLINE];
      print('change user online is ${isOnline}');
      print("user id is ${widget.user.userId}");
      setState(() {});

    });

  }


  @override
  void dispose() {
    _messages.drain();
    _textController.dispose();
    _messagesController.dispose();


    if(_typingTimer?.isActive ?? false)
      _typingTimer?.cancel();

    //Cancel an in-progress voice recording and release the native recorder
    cancelRecord();

    //When user dispose the screen => change typing state to false in firebase
    if(_iAmWriting){

      print('user has text and left screen => change typing state');

      UserModel().getUser(UserModel().user.userId).then((snapshot){

        Map<String , dynamic> data = snapshot.data()! as Map<String, dynamic>;
        Map<String , dynamic> typings = data[USER_TYPING] as Map<String, dynamic>? ?? <String, dynamic>{};

        typings[widget.user.userId] = false;
        data[USER_TYPING] = typings;
        FirebaseFirestore.instance.collection(C_USERS).doc(UserModel().user.userId).update(data);

      });

      _iAmWriting = false;
    }


    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    /// Initialization
    _i18n = AppLocalizations.of(context);
    _pr = ProgressDialog(context);

    return Scaffold(
        appBar: AppBar(
          // Show User profile info
          title: GestureDetector(
            child: ListTile(
              contentPadding: const EdgeInsets.only(left: 0),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(widget.user.userProfilePhoto),
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(widget.user.userFullname, style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10,),

                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(500) ,   color: isOnline ? Colors.green : Colors.grey,),
                  )
                ],
              ),
            ),
            onTap: () {
              /// Go to profile screen
              Navigator.of(context).push(
                  MaterialPageRoute(
                  builder: (context) =>
                      ProfileScreen(user: widget.user, showButtons: false)));
            },
          ),
          actions: <Widget>[
            /// Actions list
            PopupMenuButton<String>(
              initialValue: "",
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                /// Delete Chat
                PopupMenuItem(
                    value: "delete_chat",
                    child: Row(
                      children: <Widget>[
                        SvgIcon(
                            "assets/icons/trash_icon.svg",
                            width: 20,
                            height: 20,
                            color: Theme.of(context).primaryColor),
                        SizedBox(width: 5),
                        Text(_i18n.translate("delete_conversation")),
                      ],
                    )),

                /// Delete Match
                PopupMenuItem(
                    value: "delete_match",
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.highlight_off,
                            color: Theme.of(context).primaryColor),
                        SizedBox(width: 5),
                        Text(_i18n.translate("delete_match"))
                      ],
                    )),
              ],
              onSelected: (val) {
                /// Control selected value
                switch (val) {
                  case "delete_chat":

                    /// Delete chat
                    confirmDialog(context,
                        title: _i18n.translate("delete_conversation"),
                        message: _i18n.translate("conversation_will_be_deleted"),
                        negativeAction: () => Navigator.of(context).pop(),
                        positiveText: _i18n.translate("DELETE"),
                        positiveAction: () async {
                          // Close the confirm dialog
                          Navigator.of(context).pop();

                          // Show processing dialog
                          _pr.show(_i18n.translate("processing"));

                          /// Delete chat
                          await _messagesApi.deleteChat(widget.user.userId);

                          // Hide progress
                          await _pr.hide();

                        });
                    break;

                  case "delete_match":
                    errorDialog(context,
                        title: _i18n.translate("delete_match"),
                        message:
                            "${_i18n.translate("are_you_sure_you_want_to_delete_your_match_with")}: "
                            "${widget.user.userFullname}?\n\n"
                            "${_i18n.translate("this_action_cannot_be_reversed")}",
                        positiveText: _i18n.translate("DELETE"),
                        negativeAction: () => Navigator.of(context).pop(),
                        positiveAction: () async {
                          // Show processing dialog
                          _pr.show(_i18n.translate("processing"));

                          /// Delete match
                          await _matchesApi.deleteMatch(widget.user.userId);

                          /// Delete chat
                          await _messagesApi.deleteChat(widget.user.userId);

                          /// Delete like
                          await _likesApi.deleteLike(widget.user.userId);

                          // Hide progress
                          _pr.hide();
                          // Hide dialog
                          Navigator.of(context).pop();
                          // Close chat screen
                          Navigator.of(context).pop();
                        });
                    break;
                }
                print("Selected action: $val");
              },
            ),
          ],
        ),
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: Colors.white,
          child: Stack(
            children: [

              ///////////////////// * chat screen * /////////////////////
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: <Widget>[
                    /// how message list
                    Expanded(child: _showMessages()),


                    /// Text Composer
                    Padding(
                      // Sits above BOTH the keyboard (resizeToAvoidBottomInset
                      // lifts the body while viewInsets > 0) and the Android
                      // nav bar when the keyboard is closed.
                      padding: EdgeInsets.only(
                          left: 8,
                          right: 8,
                          top: 0,
                          bottom: MediaQuery.of(context).viewInsets.bottom > 0
                              ? 5
                              : MediaQuery.of(context).padding.bottom + 5),
                      child: Container(
                        height: 56,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [

                            ////////////////////////////////////////////Button
                            Container(
                              width: 53,
                              height: 50,),

                            SizedBox(width: 3,),

                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(50),
                                  borderRadius: BorderRadius.circular(50)
                                ),
                                child: ListTile(
                                    title: TextField(
                                      controller: _textController,
                                      minLines: 1,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.done,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                          hintText: _i18n.translate("type_a_message"),
                                          border: InputBorder.none),
                                      onChanged: (text) {

                                        _updateTimer();

                                        //When user typing is changed status of type in firestore
                                        if(text.isNotEmpty){

                                          if(!_isComposing)
                                            setState(() { _isComposing = text.isNotEmpty; });


                                          if(!_iAmWriting){

                                            UserModel().getUser(UserModel().user.userId).then((snapshot){

                                              Map<String , dynamic> data = snapshot.data()! as Map<String, dynamic>;
                                              Map<String , dynamic> typings = data[USER_TYPING] as Map<String, dynamic>? ?? <String, dynamic>{};

                                              typings[widget.user.userId] = true;
                                              data[USER_TYPING] = typings;
                                              FirebaseFirestore.instance.collection(C_USERS).doc(UserModel().user.userId).update(data);

                                            });

                                            _iAmWriting = true;
                                          }

                                        }
                                        //TextField is empty
                                        else {

                                          if(_isComposing)
                                            setState(() { _isComposing = text.isNotEmpty; });


                                          if(_iAmWriting){

                                            UserModel().getUser(UserModel().user.userId).then((snap){

                                              Map<String , dynamic> data = snap.data()! as Map<String, dynamic>;
                                              Map<String , dynamic> typings = data[USER_TYPING] as Map<String, dynamic>? ?? <String, dynamic>{};

                                              typings[widget.user.userId] = false;
                                              data[USER_TYPING] = typings;
                                              FirebaseFirestore.instance.collection(C_USERS).doc(UserModel().user.userId).update(data);

                                            });

                                            _iAmWriting = false;
                                          }
                                        }

                                      },
                                      onEditingComplete: (){

                                        if(_typingTimer?.isActive ?? false)
                                          _typingTimer?.cancel();

                                        _stopTypingStatus();
                                      },
                                    ),
                                    trailing: IconButton(
                                        icon: Icon(Icons.send,
                                            color: _isComposing
                                                ? Theme.of(context).primaryColor
                                                : Colors.grey),
                                        onPressed: _isComposing
                                            ? () async {


                                          if(UserModel().user.userGender != "affiliate"){
                                            //Only user is VIP
                                            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 1.0){

                                              if(_typingTimer?.isActive ?? false)
                                                _typingTimer?.cancel();


                                              //change typing status
                                              _stopTypingStatus();

                                              /// Get text
                                              final text = _textController.text.trim();

                                              /// clear input text
                                              _textController.clear();
                                              setState(() {_isComposing = false;});

                                              /// Send text message
                                              await _sendMessage(type: 'text', text: text);

                                              /// Update scroll
                                              _scrollMessageList();
                                            }
                                            else {

                                              if(_typingTimer?.isActive ?? false)
                                                _typingTimer?.cancel();

                                              //change typing status
                                              _stopTypingStatus();



                                              /// Show VIP dialog
                                              showDialog(
                                                  context: context,
                                                  builder: (context) => VipDialog());
                                            }
                                          }
                                          else {

                                            if(_typingTimer?.isActive ?? false)
                                              _typingTimer?.cancel();

                                            //change typing status
                                            _stopTypingStatus();

                                            /// Get text
                                            final text = _textController.text.trim();

                                            /// clear input text
                                            _textController.clear();
                                            setState(() {_isComposing = false;});

                                            /// Send text message
                                            await _sendMessage(type: 'text', text: text);

                                            /// Update scroll
                                            _scrollMessageList();
                                          }

                                        }
                                            : null)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ///////////////////// * media button * /////////////////////
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  // Nav-bar aware so the media FAB never hides behind the
                  // gesture pill / 3-button nav.
                  padding: EdgeInsets.fromLTRB(
                      7.5,
                      7.5,
                      7.5,
                      MediaQuery.of(context).viewInsets.bottom > 0
                          ? 7.5
                          : MediaQuery.of(context).padding.bottom + 7.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// Mini media buttons (expandable)
                      if (_mediaOpen) ..._mediaButtons(),

                      const SizedBox(height: 10),

                      /// Toggle button
                      FloatingActionButton(
                        heroTag: "media_toggle",
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Icon(
                          _mediaOpen ? Icons.close : Icons.add,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _mediaOpen = !_mediaOpen);
                        },
                      ),
                    ],
                  ),
                ),
              )



              // Positioned(
              //   bottom: 3,
              //   left: 4,
              //   child: AnimatedFloatingActionButton(
              //     animatedIconData: AnimatedIcons.menu_home,
              //     colorEndAnimation: Theme.of(context).primaryColor.withOpacity(0.8),
              //     colorStartAnimation: Theme.of(context).primaryColor,
              //     fabButtons: _favButtons(),
              //   ),
              // ),

            ],
          ),
        ),
    );

  }

  /// Build bubble message
  Widget _showMessages() {
    return StreamBuilder<QuerySnapshot>(
        stream: _messages,
        builder: (context, snapshot) {
          // Check data
          if (!snapshot.hasData)
            return MyCircularProgress();
          else {
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                      controller: _messagesController,
                      reverse: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {


                        // Get message list
                        final List<DocumentSnapshot> messages =
                            snapshot.data!.docs.reversed.toList();
                        print('size of messages: ${messages.length}');


                        // Get message doc map (untyped snapshots => cast)
                        final Map<String, dynamic> msg =
                            messages[index].data()! as Map<String, dynamic>;
                        print('message data TEXT: ${msg[MESSAGE_TEXT]}');
                        print('message data TYPE: ${msg[MESSAGE_TYPE]}');
                        print('message data AUDIO_LINK: ${msg[MESSAGE_AUDIO_LINK]}');
                        print('message data GIF_LINK: ${msg[MESSAGE_GIF_LINK]}');
                        print('message data IMG_LINK: ${msg[MESSAGE_IMG_LINK]}');


                        /// Variables
                        bool isUserSender;
                        String userPhotoLink;
                        final bool isAudio = msg[MESSAGE_TYPE] == 'audio';  //NEW
                        final bool isGif = msg[MESSAGE_TYPE] == 'gif';  //NEW
                        final bool isSticker = msg[MESSAGE_TYPE] == 'sticker';  //NEW
                        final bool isImage = msg[MESSAGE_TYPE] == 'image';
                        final String textMessage = msg[MESSAGE_TEXT];
                        final String audioLink = msg[MESSAGE_AUDIO_LINK];  //NEW
                        final String gifLink = msg[MESSAGE_GIF_LINK];  //NEW
                        final String stickerLink = msg[MESSAGE_STICKER_LINK];  //NEW
                        final String? imageLink = msg[MESSAGE_IMG_LINK];
                        final String timeAgo = timeago.format(msg[TIMESTAMP].toDate());

                        /// Check user id to get info
                        if (msg[USER_ID] == UserModel().user.userId) {
                          isUserSender = true;
                          userPhotoLink = UserModel().user.userProfilePhoto;
                        }
                        else {
                          isUserSender = false;
                          userPhotoLink = widget.user.userProfilePhoto;
                        }
                        // Show chat bubble
                        return ChatMessage(
                          isSticker: isSticker,
                          stickerLink: stickerLink,
                          isGif: isGif,
                          gifLink: gifLink,
                          isAudio: isAudio,
                          audioLink: audioLink,
                          isUserSender: isUserSender,
                          isImage: isImage,
                          userPhotoLink: userPhotoLink,
                          textMessage: textMessage,
                          imageLink: imageLink,
                          timeAgo: timeAgo,
                        );
                      }),
                ),

                //Typing section  (NEW)
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  child: Visibility(
                    visible: _isVisibleTyping,
                    child: AnimatedOpacity(
                      opacity: _opacityTyping,
                      duration: Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: MediaQuery.of(context).size.width,
                        height: 50,
                        child: Center(
                          child: Image.asset(
                            'assets/images/typing.gif',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                //Typing section  (NEW)

              ],
            );
          }
        });
  }

  void _stopTypingStatus() {

    UserModel().getUser(UserModel().user.userId).then((snapshot){

      Map<String , dynamic> data = snapshot.data()! as Map<String, dynamic>;
      Map<String , dynamic> typings = data[USER_TYPING] as Map<String, dynamic>? ?? <String, dynamic>{};

      typings[widget.user.userId] = false;
      data[USER_TYPING] = typings;
      FirebaseFirestore.instance.collection(C_USERS).doc(UserModel().user.userId).update(data);

    });

    _iAmWriting = false;
  }

  Future<bool> checkPermission() async {
    if (!await Permission.microphone.isGranted) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        return false;
      }
    }
    return true;
  }

  Future<String> getFilePath() async {
    Directory storageDirectory = await getApplicationDocumentsDirectory();
    String sdPath = storageDirectory.path + "/record";

    var d = Directory(sdPath);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }

    return sdPath + "/voice_${Random().nextInt(10000000)}.m4a";
  }


  //Start Recording (native MediaRecorder via MethodChannel - AAC-LC / .m4a)
  void startRecord() async {
    bool hasPermission = await checkPermission();
    if (hasPermission) {
      recordFilePath = await getFilePath();

      try {
        //Ask the native side to start recording into [recordFilePath]
        final String? path = await _voiceRecorderChannel
            .invokeMethod<String>('start', recordFilePath);

        //Change color
        if (path != null) {
          isRecord = true;
          if (mounted) setState(() {});
        }
      } on PlatformException catch (e) {
        print('startRecord() -> error: ${e.message}');
      }
    }
    else {}
    //setState(() {});
  }


  //Stop Recording
  void stopRecord() async {
    try {
      //Native side stops and returns the recorded file path (or null)
      final String? path = await _voiceRecorderChannel.invokeMethod<String>('stop');

      if (path != null) {
        isRecord = false;
        recordFilePath = path;
        print('stop recording');

        if (mounted) setState(() {});

        await uploadAudio();
      }
      else {
        isRecord = false;
        print('stay recording');
      }
    } on PlatformException catch (e) {
      isRecord = false;
      print('stopRecord() -> error: ${e.message}');
    }
  }


  //Cancel Recording (native side releases the recorder and deletes the file)
  void cancelRecord() {
    if (!isRecord) return;
    _voiceRecorderChannel.invokeMethod('cancel').catchError((e) {
      print('cancelRecord() -> error: $e');
    });
    isRecord = false;
  }


  //Upload Audio
  uploadAudio() {

    // _pr.show(_i18n.translate("sending"));

    // Per-user storage path: uploads/messages/{uid}/audio{timestamp}.m4a
    final Reference firebaseStorageRef = FirebaseStorage.instance
        .ref()
        .child('uploads/messages/${UserModel().user.userId}/audio${DateTime.now().millisecondsSinceEpoch.toString()}.m4a');

    UploadTask task = firebaseStorageRef.putFile(File(recordFilePath));
    task.then((value) async {


      print('##############done#########');
      var audioURL = await value.ref.getDownloadURL();
      String urlFile = audioURL.toString();


      // _pr.hide();

      recordFilePath = '';

      await _sendMessage(type: 'audio', urlAudioPath: urlFile);

      // setState(() {});

    }).catchError((e) {
      // Upload failed (offline / rules): tell the user instead of
      // failing silently with no message sent
      debugPrint('uploadAudio() -> error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: APP_ERROR_COLOR,
        content: Text(AppLocalizations.of(context).translate("media_upload_failed"),
            style: const TextStyle(color: Colors.white)),
      ));
    });
  }

  List<Widget> _mediaButtons() {

    List<Widget> buttons = [

      //////////////////////////SHOW IMAGES
      FloatingActionButton(
        heroTag: "image",
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.red,
        child: Icon(Icons.camera , color: Colors.red,),
        onPressed: () async {

          //Close media buttons
          setState(() => _mediaOpen = false);

          if(UserModel().user.userGender != "affiliate"){
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              /// Send image file
              await _getImage();

              //Deduct money 10 , check if user is affiliate (not here)

              /// Update scroll
              _scrollMessageList();
            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            /// Send image file
            await _getImage();

            //Deduct money 10 , check if user is affiliate (not here)

            /// Update scroll
            _scrollMessageList();
          }


        },
      ),


      //////////////////////////SHOW Stickers
      FloatingActionButton(
        heroTag: "Stickers",
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        child: Icon(Icons.style , color: Colors.blue,),
        onPressed: () async {

          //Close media buttons
          setState(() => _mediaOpen = false);

          if(UserModel().user.userGender != "affiliate"){
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              /// Send sticker file
              await _getStickers();

              /// Update scroll
              _scrollMessageList();

            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            /// Send sticker file
            await _getStickers();


            /// Update scroll
            _scrollMessageList();
          }



        },
      ),


      //////////////////////////SHOW GIFS
      FloatingActionButton(
        heroTag: "gif",
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        child: Icon(Icons.extension , color: Colors.blue,),
        onPressed: () async {

          //Close media buttons
          setState(() => _mediaOpen = false);

          if(UserModel().user.userGender != "affiliate"){
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              /// Send gif file
              await _getGifs();

              /// Update scroll
              _scrollMessageList();

            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            /// Send gif file
            await _getGifs();

            /// Update scroll
            _scrollMessageList();
          }

        },
      ),


      //////////////////////////SHOW VOICE MESSAGE
      FloatingActionButton(
        heroTag: "voice",
        mini: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        onPressed: null,
        child: GestureDetector(
            onLongPress: (){

              if(UserModel().user.userGender != "affiliate"){
                //Start Record
                //Only user is VIP
                if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

                  //Record file.m4a (native MediaRecorder)
                  startRecord();
                }
                else {
                  /// Show VIP dialog
                  showDialog(context: context,
                      builder: (context) => VipDialog());
                }
              }
              else {
                //Record file.m4a (native MediaRecorder)
                startRecord();
              }

            },
            onLongPressUp: (){

              //stop record
              stopRecord();

              //deduct 10 money of user (not here)

              /// Update scroll
              _scrollMessageList();

            },
            child: Icon(Icons.mic_none_rounded , color: isRecord ? Colors.yellowAccent : Colors.green,)
        ),
      ),
    ];

    return buttons;

  }

  List<Widget> _favButtons() {

    List<Widget> buttons = [


      Container(
        width: 75,
        height: 75,
        color: Colors.red,
        child: Center(
          child:  GestureDetector(
              onLongPress: (){

                if(UserModel().user.userGender != "affiliate"){
                  //Start Record
                  //Only user is VIP
                  if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

                    //Record file.m4a
                    startRecord();
                  }
                  else {
                    /// Show VIP dialog
                    showDialog(context: context,
                        builder: (context) => VipDialog());
                  }
                }
                else {

                  //Record file.m4a
                  startRecord();
                }




              },
              onLongPressEnd: (details){
                print('called');

                //stop record
                stopRecord();

                //deduct 10 money of user (not here)

                /// Update scroll
                _scrollMessageList();


              },
              child: Icon(Icons.mic_none_rounded , color: isRecord ? Colors.yellowAccent : Colors.green,)
          ),
        ),
      ),



      //////////////////////////////// * Voice message * ////////////////////////////////

      GestureDetector(
        onLongPress: (){

          if(UserModel().user.userGender != "affiliate"){
            //Start Record
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              //Record file.m4a
              startRecord();
            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            //Record file.m4a
            startRecord();
          }




        },
        onLongPressEnd: (d){

          // if(UserModel().user.userWallet > 0.0){   //Only user is VIP
          //
          //
          // }
          // else {
          //   /// Show VIP dialog
          //   showDialog(context: context,
          //       builder: (context) => VipDialog());
          // }


          //stop record
          stopRecord();

          //deduct 10 money of user (not here)

          /// Update scroll
          _scrollMessageList();


        },
        child: FloatingActionButton(
          onPressed: (){},
          backgroundColor: Colors.white,
          child: Center(
            child:  Icon(Icons.mic_none_rounded , color: isRecord ? Colors.yellowAccent : Colors.green,),
          ),
        ),
      ),



      //////////////////////////////// * Camera/Gallery * ////////////////////////////////
      FloatingActionButton(
        onPressed: () async{

          if(UserModel().user.userGender != "affiliate"){
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              /// Send image file
              await _getImage();

              //Deduct money 10 , check if user is affiliate (not here)

              /// Update scroll
              _scrollMessageList();
            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            /// Send image file
            await _getImage();

            //Deduct money 10 , check if user is affiliate (not here)

            /// Update scroll
            _scrollMessageList();
          }

        },
        backgroundColor: Colors.white,
        child: Center(
          child: Icon(Icons.camera , color: Colors.red,),
        ),
      ),



      //////////////////////////////// * Gifs * ////////////////////////////////
      FloatingActionButton(
        onPressed: () async{

          if(UserModel().user.userGender != "affiliate"){
            //Only user is VIP
            if(UserModel().user.userWallet > 0.0 && UserModel().user.userWallet >= 10.0){

              /// Send gif file
              await  _getGifs();

              //Deduct money 10 , check if user is affiliate (not here)


              /// Update scroll
              _scrollMessageList();

            }
            else {
              /// Show VIP dialog
              showDialog(context: context,
                  builder: (context) => VipDialog());
            }
          }
          else {

            /// Send gif file
            await  _getGifs();

            //Deduct money 10 , check if user is affiliate (not here)


            /// Update scroll
            _scrollMessageList();
          }
        },
        backgroundColor: Colors.white,
        child: Center(
          child: Icon(Icons.style , color: Colors.blue,),
        ),
      ),

    ];

    return buttons;
  }

  void _updateTimer() {

    if(_typingTimer?.isActive ?? false)
      _typingTimer?.cancel();

    //After 3 seconds  => typing is false in firestore
    _typingTimer = Timer(const Duration(seconds: 3) , (){
      _stopTypingStatus();
    });
  }

}
