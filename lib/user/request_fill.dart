import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mm_nrc_kit/mm_nrc_kit.dart';
import 'package:nft_cert/components/status_card.dart';
import 'package:nft_cert/components/user_event_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestFill extends StatefulWidget {
  @override
  State<RequestFill> createState() => _EventListState();

  final String orgId;
  final String cereId;
  final String eventName;
  final String organizationName;
  final bool verified;
  final bool available;

  RequestFill({
    required this.orgId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
  });
}

class _EventListState extends State<RequestFill> {
  final TextEditingController _textController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool isVerified = false;

  bool isSubmitted = false;

  String eventID = "";
  bool isLoading = false;

  String? userid;
  String? email;
  String? walletAddress;

  // Retrieve user info from SharedPreferences
  Future<void> getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userid = prefs.getString('uid');
      email = prefs.getString('email');
      walletAddress = prefs.getString('walletAddress');
    });
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    print("User ID : " + userid!);
    print("Event ID : " + widget.cereId);

    var userDoc = await _firestore
        .collection('certification_request_form')
        .where('userId', isEqualTo: userid)
        .where('cereId', isEqualTo: widget.cereId)
        .limit(1)
        .get();

    if (userDoc.docs.isNotEmpty) {
      isSubmitted = true;
      var data = userDoc.docs.first.data();
      isVerified = data['verified'] ?? false;

      // Auto-fill the fields with existing data
      Map<String, dynamic> attributes = data['attributes'] ?? {};
      attributes.forEach((key, value) async {
        var attributeData = attributes[key];

        // Ensure a controller exists for the text field
        if (_controllers.containsKey(key)) {
          // Handle Text, Number, Date, and Dropdown fields
          if (attributeData is String && !_pickedImages.containsKey(key)) {
            setState(() {
              _controllers[key]?.text = attributeData;
            });
          }

          // Handle Photo field (if the value is a URL)
          if (attributeData is String && attributeData.startsWith('http')) {
            setState(() {
              _pickedImages[key] = File(attributeData);
            });
          }
        }
      });
    } else {
      print("No existing data found for User ID: " +
          userid! +
          " and Event ID: " +
          widget.cereId);
    }
  }

  final Map<String, TextEditingController> _controllers = {};
  Map<String, File?> _pickedImages = {};

  // Function to pick an image using image picker
  Future<void> _pickImage(String fieldName) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImages[fieldName] = File(image.path);
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _controllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  // Validate all the fields are filled
  bool _validateFields(List<dynamic> attributes) {
    for (var attribute in attributes) {
      String fieldName = attribute['field'];
      String fieldType = attribute['type'];

      // Check if the field is not filled
      if (fieldType == 'Photo' && _pickedImages[fieldName] == null) {
        print("Photo Empty");
        return false;
      } else if (_controllers[fieldName]?.text.isEmpty == true &&
          fieldType != "Photo") {
        print("Text Empty : " + fieldName);
        return false;
      }
    }
    return true;
  }

  // Submit the form data (update if exists, create if not)
  Future<void> _submitForm(List<dynamic> attributes) async {
    if (!isVerified) {
      setState(() {
        isLoading = true; // Show loading state
      });

      try {
        Map<String, dynamic> attributeData = {};

        // Upload images and collect form data
        for (var attribute in attributes) {
          String fieldName = attribute['field'];
          String fieldType = attribute['type'];

          if (fieldType == 'Photo') {
            // Upload the photo to Firebase Storage

            if (_pickedImages[fieldName] != null &&
                !_pickedImages[fieldName]
                    .toString()
                    .startsWith('File: \'https:')) {
              print("Image : " + _pickedImages[fieldName].toString());

              String fileName =
                  'images/${widget.cereId}/${fieldName}_${DateTime.now()}.png';
              Reference storageRef = _storage.ref().child(fileName);

              UploadTask uploadTask =
                  storageRef.putFile(_pickedImages[fieldName]!);
              TaskSnapshot snapshot = await uploadTask;
              String downloadUrl = await snapshot.ref.getDownloadURL();
              attributeData[fieldName] =
                  downloadUrl; // Store the URL in Firestore
            } else {
              attributeData[fieldName] = _controllers[fieldName]?.text;
            }
          } else {
            attributeData[fieldName] = _controllers[fieldName]?.text;
          }
        }

        print(attributeData);

        // Check if the document exists for this user and cereId
        var userDoc = await _firestore
            .collection('certification_request_form')
            .where('userId', isEqualTo: userid)
            .where('cereId', isEqualTo: widget.cereId)
            .limit(1)
            .get();

        if (userDoc.docs.isEmpty) {
          // If no document exists, create a new one
          await _firestore.collection('certification_request_form').add({
            'cereId': widget.cereId,
            'orgId': widget.orgId,
            'userId': userid,
            'attributes': attributeData,
            'verified': false,
            'createDate': FieldValue.serverTimestamp(),
          });
        } else {
          // If a document exists, update it
          if (!isVerified) {
            await _firestore
                .collection('certification_request_form')
                .doc(userDoc.docs.first.id)
                .update({
              'attributes': attributeData,
              'createDate': FieldValue.serverTimestamp(),
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('This request is verified and cannot be edited.')),
            );
            return;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form Submitted Successfully!')),
        );

        _clearFields(attributes);

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting form: $e')),
        );
      } finally {
        setState(() {
          isLoading = false; // Hide loading state
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your Submission already verified!')),
      );
    }
  }

  // Function to clear all the form fields
  void _clearFields(List<dynamic> attributes) {
    // Clear text fields
    for (var attribute in attributes) {
      String fieldName = attribute['field'];
      _controllers[fieldName]?.clear();
    }

    // Clear selected images
    _pickedImages.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NFT',
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Certification',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      UserEventCard(
                        orgId: widget.orgId,
                        cereId: widget.cereId,
                        eventName: widget.eventName,
                        organizationName: widget.organizationName,
                        verified: widget.verified,
                        available: widget.available,
                        clickable: false,
                      ),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('certification_request_form')
                            .where('cereId', isEqualTo: widget.cereId)
                            .where('userId', isEqualTo: userid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty) {
                            var docData = snapshot.data!.docs.first.data()
                                as Map<String, dynamic>;

                            isVerified = docData['verified'] ?? false;

                            // print("Verified : " + isVerified);

                            return StatusCard(
                              verified: isVerified,
                            );
                          }

                          return SizedBox.shrink(); // Return empty if no data
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Certification Request',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 30),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      // Validate all fields
                                      var attributes = (await _firestore
                                              .collection('certification_event')
                                              .doc(widget.cereId)
                                              .get())
                                          .data()!['attributes'];
                                      if (_validateFields(attributes)) {
                                        await _submitForm(attributes);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Please fill in all fields or pick required photo.')),
                                        );
                                      }
                                    },
                              child: isLoading
                                  ? SizedBox(
                                      height: 20.0, // Adjust height as needed
                                      width: 20.0, // Adjust width as needed
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                        strokeWidth:
                                            3.0, // Adjust thickness of the indicator
                                      ),
                                    )
                                  : Text(
                                      'Submit',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: _firestore
                              .collection('certification_event')
                              .doc(widget.cereId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            // Check if the document exists
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Center(child: Text("No event data found"));
                            }

                            // Retrieve attributes map from the document
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;
                            List<dynamic> attributes = data['attributes'] ?? [];

                            return ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: attributes.length,
                              itemBuilder: (context, index) {
                                var attribute = attributes[index];
                                String fieldName = attribute['field'];
                                String fieldType = attribute['type'];
                                List<String> dropdownOptions =
                                    attribute['options'] ?? [];

                                // Ensure a controller exists for each text field
                                if (!_controllers.containsKey(fieldName)) {
                                  _controllers[fieldName] =
                                      TextEditingController();
                                }

                                // Generate the appropriate input field based on type
                                switch (fieldType) {
                                  case 'Text':
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 16.0),
                                      child: TextFormField(
                                        controller: _controllers[fieldName],
                                        decoration: InputDecoration(
                                          labelText: fieldName,
                                          hintText: 'Enter Your $fieldName',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                        readOnly: isVerified,
                                      ),
                                    );
                                  case 'Number':
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 16.0),
                                      child: TextFormField(
                                        controller: _controllers[fieldName],
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly, // This ensures only numbers are allowed
                                        ],
                                        decoration: InputDecoration(
                                          labelText: fieldName,
                                          hintText: 'Enter Your $fieldName',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                        readOnly: isVerified,
                                      ),
                                    );
                                  case 'Date':
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 16.0),
                                      child: TextFormField(
                                        controller: _controllers[fieldName],
                                        readOnly: true,
                                        decoration: InputDecoration(
                                          labelText: fieldName,
                                          hintText: 'Pick a Date',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                        style: TextStyle(fontSize: 14),
                                        onTap: !isVerified
                                            ? () async {
                                                DateTime? pickedDate =
                                                    await showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime(1900),
                                                  lastDate: DateTime(2101),
                                                );
                                                if (pickedDate != null) {
                                                  setState(() {
                                                    _controllers[fieldName]!
                                                            .text =
                                                        pickedDate
                                                            .toLocal()
                                                            .toString()
                                                            .split(' ')[0];
                                                  });
                                                }
                                              }
                                            : null, // Disable date picker if verified
                                      ),
                                    );
                                  case 'Photo':
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          top: 5, bottom: 16.0),
                                      child: GestureDetector(
                                        onTap: !isVerified
                                            ? () => _pickImage(fieldName)
                                            : null, // Disable image picker if verified
                                        child: Container(
                                          height: 150,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Center(
                                            child:
                                                _pickedImages[fieldName] != null
                                                    ? _pickedImages[fieldName]!
                                                            .path
                                                            .startsWith('http')
                                                        ? Image.network(
                                                            _pickedImages[
                                                                    fieldName]!
                                                                .path,
                                                            fit: BoxFit.cover,
                                                          )
                                                        : Image.file(
                                                            _pickedImages[
                                                                fieldName]!,
                                                            fit: BoxFit.cover,
                                                          )
                                                    : Text(fieldName),
                                          ),
                                        ),
                                      ),
                                    );
                                  case 'Dropdown':
                                    // Ensure _controllers and dropdownOptions are initialized for this field
                                    if (!_controllers.containsKey(fieldName)) {
                                      _controllers[fieldName] =
                                          TextEditingController();
                                    }
                                    List<dynamic> dropdownOptions =
                                        attribute['dropdownOptions'] ?? [];
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16.0),
                                      child: DropdownButtonFormField<String>(
                                        value: _controllers[fieldName]!.text ==
                                                ""
                                            ? null
                                            : _controllers[fieldName]!
                                                .text, // Store the currently selected value
                                        items:
                                            dropdownOptions.map((var option) {
                                          return DropdownMenuItem<String>(
                                            value: option,
                                            child: Text(option),
                                          );
                                        }).toList(),
                                        onChanged: !isVerified
                                            ? (newValue) {
                                                _controllers[fieldName]?.text =
                                                    newValue!; // Store selected value in controller
                                              }
                                            : null, // Disable dropdown if verified
                                        decoration: InputDecoration(
                                          labelText: fieldName,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    );
                                  case 'MM NRC':
                                    return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 15,
                                        ),
                                        child: AbsorbPointer(
                                          absorbing: isVerified,
                                          child: NRCField(
                                            nrcValue:
                                                _controllers[fieldName]!.text,
                                            language: NrcLanguage.english,
                                            leadingTitleFontSize: 14,
                                            trailingTitleFontSize: 14,
                                            leadingTitleColor: Colors.black,
                                            // Change color to indicate disabled state
                                            backgroundColor: Colors.white,
                                            pickerItemColor: isVerified
                                                ? Colors.grey
                                                : Colors
                                                    .black, // Change picker color if necessary
                                            borderColor: Colors
                                                .black, // Change border color if necessary
                                            borderRadius: 20,
                                            borderWidth: 0.4,
                                            onCompleted: isVerified
                                                ? (value) {} // Disable the onChanged callback if verified
                                                : (value) {
                                                    debugPrint(
                                                        "onCompleted : $value");
                                                  },
                                            onChanged: isVerified
                                                ? (value) {} // Disable the onChanged callback if verified
                                                : (value) {
                                                    _controllers[fieldName]
                                                        ?.text = value!;
                                                  },
                                          ),
                                        ));

                                  default:
                                    return SizedBox.shrink();
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 30,
          right: 30,
          top: 0,
          bottom: 30,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios),
              iconSize: 30,
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
