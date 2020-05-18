
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:toast/toast.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Ticket Data Extractor',
        theme: ThemeData(primarySwatch: Colors.pink),
        home: ImageInput());
  }
}

class ImageInput extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImageInput();
  }
}

class _ImageInput extends State<ImageInput> {
  // To store the file provided by the image_picker
  File _imageFile;

  // To track the file uploading state
  bool _isUploading = false;
  bool _isUploaded = false;

  String baseUrl = 'http://192.168.43.93:8000/api/';
  TextEditingController fromToController;
  TextEditingController dateController;
  TextEditingController timeController;
  TextEditingController perHeadPriceController;
  TextEditingController numofTravellerController;
  TextEditingController netPriceController;
  String fromTo  = '';
  String date = '';
  String time = '';
  String perHeadPrice = '';
  String numOfTraveller = '';
  String netPrice = '';
  @override
  void initState() {
    super.initState();
  }
  void setController(){
    setState(() {
      fromToController = new TextEditingController(text: fromTo);
      dateController = new TextEditingController(text: date);
      timeController = new TextEditingController(text: time);
      perHeadPriceController = new TextEditingController(text: perHeadPrice);
      numofTravellerController = new TextEditingController(text: numOfTraveller);
      netPriceController = new TextEditingController(text: netPrice);
    });
  }

  void _getImage(BuildContext context, ImageSource source) async {
    File image = await ImagePicker.pickImage(source: source);

    setState(() {
      _imageFile = image;
    });

    // Closes the bottom sheet
    Navigator.pop(context);
  }

  Future<Map<String, dynamic>> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });

    // Find the mime type of the selected file by looking at the header bytes of the file
    final mimeTypeData =
        lookupMimeType(image.path, headerBytes: [0xFF, 0xD8]).split('/');

    // Intilize the multipart request
    final imageUploadRequest =
        http.MultipartRequest('POST', Uri.parse(baseUrl));

    // Attach the file in the request
    final file = await http.MultipartFile.fromPath('image', image.path,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]));
    // Explicitly pass the extension of the image with request body
    // Since image_picker has some bugs due which it mixes up
    // image extension with file name like this filenamejpge
    // Which creates some problem at the server side to manage
    // or verify the file extension
    //imageUploadRequest.fields['image'] = mimeTypeData[0];
    imageUploadRequest.fields['ext'] = mimeTypeData[1];
    imageUploadRequest.files.add(file);
    print(image.path);
    print(mimeTypeData[0]);
    print("punit kutta");
    print(imageUploadRequest);
    print(file);

    try {
      final streamedResponse = await imageUploadRequest.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> responseData = json.decode(response.body);

      //_resetState();

      return responseData;
    } catch (e) {
      print(e);
      return null;
    }
  }

  void _startUploading() async {
    final Map<String, dynamic> response = await _uploadImage(_imageFile);
    setState(() {
      _isUploaded = true;
      _isUploading = false;
    });
    //setController();
    print(response);
    // Check if any error occured
    if (response['response'] == '0' || response == null || response.containsKey("error")){
      //data = jsonDecode(response);
      setState(() {
        fromTo  = '';
        date = '';
        time = '';
        perHeadPrice = '';
        numOfTraveller = '';
        netPrice = '';
      });
      Toast.show("Image Upload Failed!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    } else {
      setState(() {
        fromTo  = response['FromTo'];
        date = response['date'];
        time = response['time'];
        perHeadPrice = response['PerHeadPrice'];
        numOfTraveller = response['total_travellers'];
        netPrice = response['total_price'];
      });
      Toast.show("Image Uploaded Successfully!!!", context,
          duration: Toast.LENGTH_LONG, gravity: Toast.BOTTOM);
    }
    setController();
  }

  void _resetState() {
    setState(() {
      _isUploading = false;
      _imageFile = null;
      _isUploaded = false;
    });
  }

  void _openImagePickerModal(BuildContext context) {
    final flatButtonColor = Theme.of(context).primaryColor;
    print('Image Picker Modal Called');
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 150.0,
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                Text(
                  'Pick an image',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 10.0,
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Camera'),
                  onPressed: () {
                    _resetState();
                    _getImage(context, ImageSource.camera);
                  },
                ),
                FlatButton(
                  textColor: flatButtonColor,
                  child: Text('Use Gallery'),
                  onPressed: () {
                    _resetState();
                    _getImage(context, ImageSource.gallery);
                  },
                ),
              ],
            ),
          );
        });
  }

  BoxDecoration myBoxDecoration() {
    return BoxDecoration(
      border: Border.all(width: 1.0),
      borderRadius: BorderRadius.all(
          Radius.circular(15.0) //         <--- border radius here
          ),
    );
  }

  Widget _buildUploadBtn() {
    Widget btnWidget = Container();

    if (_isUploading) {
      // File is being uploaded then show a progress indicator
      btnWidget = Container(
          margin: EdgeInsets.only(top: 10.0),
          child: CircularProgressIndicator());
    } else if (!_isUploading && _imageFile != null && !_isUploaded) {
      // If image is picked by the user then show a upload btn

      btnWidget = Container(
        margin: EdgeInsets.only(top: 10.0),
        child: RaisedButton(
          child: Text('Fetch Data'),
          onPressed: () {
            _startUploading();
          },
          color: Colors.pinkAccent,
          textColor: Colors.white,
        ),
      );
    }

    return btnWidget;
  }

  Widget _dataViewWidget() {
    Widget dataViewWidget = Column();
    if(_imageFile != null&& _isUploaded){
      dataViewWidget = Column(
        children: <Widget>[
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: fromToController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'FromTo',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: dateController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Date',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: timeController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Time',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: perHeadPriceController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'PerHeadPrice',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: numofTravellerController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'NumOfTraveller',
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(20.0),
            child: TextField(
              enabled: false,
              controller: netPriceController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Total Price',
              ),
            ),
          ),
        ],
      );
    }

    return dataViewWidget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket Data Extractor'),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0),
                child: OutlineButton(
                  onPressed: () => _openImagePickerModal(context),
                  borderSide: BorderSide(
                      color: Theme.of(context).accentColor, width: 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.camera_alt),
                      SizedBox(
                        width: 5.0,
                      ),
                      Text('Add Image'),
                    ],
                  ),
                ),
              ),
              _imageFile == null
                  ? Text('Please pick an image')
                  : Image.file(
                      _imageFile,
                      fit: BoxFit.cover,
                      height: 400.0,
                      alignment: Alignment.topCenter,
                      width: MediaQuery.of(context).size.width,
                    ),
              _buildUploadBtn(),
              _dataViewWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
