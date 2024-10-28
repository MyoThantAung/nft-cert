import 'package:flutter/material.dart';
import 'package:nft_cert/components/nft_card.dart';
import 'package:nft_cert/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class eventCreationScreen extends StatefulWidget {
  @override
  State<eventCreationScreen> createState() => _main_pageState();
}

class _main_pageState extends State<eventCreationScreen> {
  final PageController _pageController = PageController();

  final ApiService apiService = ApiService();
  TextEditingController _emailController = TextEditingController();
  List<String> _selectedEmails = [];
  String _currentInput = '';

  bool isLoading = false;

  List<Map<String, dynamic>> fields = [
    {
      'primaryFieldController': TextEditingController(),
      'selectedType': null,
    }
  ];
  String? selectedType; // This will store the selected value from the dropdown
  final List<String> typeOptions = [
    'Text',
    'Number',
    'Date',
    'Photo',
    'Dropdown',
    'MM NRC'
  ]; // Dropdown items

  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController organizationNameController =
      TextEditingController();

  // Get Info

  String? uid;
  String? email;
  String? orgid;
  String? org_name;
  String? org_address;
  String? org_walletAddress;

  // Retrieve user info from SharedPreferences
  Future<void> getAdminInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
      email = prefs.getString('email');
      orgid = prefs.getString('orgid');
      org_name = prefs.getString('org_name');
      org_address = prefs.getString('org_address');
      org_address = prefs.getString('org_walletAddress');
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();

    // Fetch user info when the screen loads
  }

  Future<void> loadData() async {
    await getAdminInfo();
    organizationNameController.text = org_name!;
  }

  void addNewField() {
    setState(() {
      fields.add({
        'primaryFieldController': TextEditingController(),
        'selectedType': null,
      });
    });
  }

/*

  // Method to add a new field
  void addNewField() {
    if (fields.length < 50) {
      setState(() {
        fields.add({
          'primaryFieldController': TextEditingController(),
          'selectedType': null
        });
      });
    }
  }*/

  // Method to remove a field, but prevent removing if only one field exists
  void removeField(int index) {
    if (fields.length == 1) {
      // Show a snackbar when the user tries to remove the last remaining field
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one field is required.'),
        ),
      );
    } else {
      setState(() {
        fields.removeAt(index);
      });
    }
  }

  // Method to validate fields and submit data to Firestore
  Future<void> submitData() async {
    setState(() {
      isLoading = true;
    });
    String eventName = eventNameController.text.trim();
    String organizationName = organizationNameController.text.trim();

    // Check if event name and organization name are filled
    if (eventName.isEmpty || organizationName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event Name and Organization Name cannot be empty.'),
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Check if all dynamic fields are filled
    for (var field in fields) {
      String primaryField = field['primaryFieldController'].text.trim();
      String? selectedType = field['selectedType'];

      if (primaryField.isEmpty || selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All fields must be filled before submission.'),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      if (selectedType == 'Dropdown' && field['dropdownOptions'].isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dropdown must have at least one option.'),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }
    }

    // Check if at least one email has been added
    if (_selectedEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('At least one student email must be added.'),
        ),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Prepare data for Firestore submission
    List<Map<String, dynamic>> formData = fields.map((field) {
      if (field['dropdownOptions'] != null) {
        return {
          'field': field['primaryFieldController'].text.trim(),
          'type': field['selectedType'],
          'dropdownOptions': field['dropdownOptions'],
        };
      } else {
        return {
          'field': field['primaryFieldController'].text.trim(),
          'type': field['selectedType'],
        };
      }
    }).toList();

    String docID = "";

    // If validation passes, save data to Firestore

    CollectionReference events =
        FirebaseFirestore.instance.collection('certification_event');

    try {
      DocumentReference newDoc = await events.add({
        'orgid': orgid,
        'eventName': eventName,
        'organizationName': organizationName,
        'attributes': formData,
        'verified': true,
        'available': false,
        'studentEmails': _selectedEmails,
        'createDate': FieldValue.serverTimestamp(),
      });

      docID = newDoc.id;

      final result =
          await apiService.setEventMaxLimit(docID, _selectedEmails.length);

      print(result);

      if (result['message'] == "Event max limit set successfully") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event saved successfully!'),
          ),
        );

        // Clear all fields after successful submission
        eventNameController.clear();
        _selectedEmails.clear();
        fields = [
          {
            'primaryFieldController': TextEditingController(),
            'selectedType': null
          }
        ]; // Reset fields to default one field

        setState(() {
          isLoading = false;
        }); // Update UI after clearing

        Navigator.pop(context);
      } else {
        if (docID != "") {
          await events.doc(docID).delete();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save event'),
          ),
        );
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (docID != "") {
        await events.doc(docID).delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save event: $e'),
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  // Method to handle dropdown options
  void openDropdownOptionsDialog(int fieldIndex) {
    if (fields[fieldIndex]['dropdownOptions'] == null) {
      fields[fieldIndex]['dropdownOptions'] = [];
    }

    TextEditingController newItemController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Manage Dropdown Items"),
              content: Container(
                // Set a maximum height for the dialog content
                width: double.maxFinite,
                height: 300, // Adjust height as needed
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: newItemController,
                      decoration: InputDecoration(
                        labelText: 'Add Dropdown Item',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: fields[fieldIndex]['dropdownOptions'].length,
                        itemBuilder: (context, itemIndex) {
                          return ListTile(
                            title: Text(fields[fieldIndex]['dropdownOptions']
                                [itemIndex]),
                            trailing: IconButton(
                              icon:
                                  Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  fields[fieldIndex]['dropdownOptions']
                                      .removeAt(itemIndex);
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (newItemController.text.isNotEmpty) {
                      setState(() {
                        fields[fieldIndex]['dropdownOptions']
                            .add(newItemController.text.trim());
                      });
                      newItemController.clear();
                    }
                  },
                  child: Text("Add"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Done"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Admin badge
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 0,
                  top: 0,
                  bottom: 5,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 0,
                  bottom: 10,
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

              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Certification Event',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
                            onPressed: isLoading ? null : submitData,
                            child: isLoading
                                ? SizedBox(
                                    height: 20.0, // Adjust height as needed
                                    width: 20.0, // Adjust width as needed
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
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
                      SizedBox(height: 20),
                      TextFormField(
                        controller: eventNameController,
                        decoration: InputDecoration(
                          labelText: 'Certification Event Name',
                          hintText: 'Enter Certification Event',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        enabled: false,
                        controller: organizationNameController,
                        decoration: InputDecoration(
                          labelText: 'Organization Name',
                          hintText: 'Enter Organization Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                      ),

                      SizedBox(height: 20),

                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Add Student Email',
                          hintText: 'Add Email',
                          errorText: _isValidEmail(_currentInput) ||
                                  _currentInput.isEmpty
                              ? null
                              : 'Invalid email format',
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _addEmail,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                        ),
                        onChanged: (input) {
                          setState(() {
                            _currentInput = input;
                          });
                        },
                        onSubmitted: (_) => _addEmail(),
                      ),

                      SizedBox(height: 16),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: _selectedEmails.map((email) {
                                return InputChip(
                                  label: Text(email),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedEmails.remove(email);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),
                      // Dynamic Fields
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: fields.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.only(
                              left: 0,
                              right: 0,
                              top: 0,
                              bottom: 15,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: fields[index]
                                        ['primaryFieldController'],
                                    decoration: InputDecoration(
                                      labelText: 'Field',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: fields[index]['selectedType'],
                                    decoration: InputDecoration(
                                      labelText: 'Type',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black),
                                    items: typeOptions.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(
                                          type,
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        fields[index]['selectedType'] =
                                            newValue;
                                        // Trigger dropdown options dialog when 'Dropdown' is selected
                                        if (newValue == 'Dropdown') {
                                          openDropdownOptionsDialog(index);
                                        }
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(width: 10),
                                Container(
                                  height: 50,
                                  width: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: IconButton(
                                    icon:
                                        Icon(Icons.remove, color: Colors.white),
                                    onPressed: () {
                                      removeField(index);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 40),
                            ),
                            onPressed: addNewField,
                            child: Text(
                              'Add New Field',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16.0),
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

  // Function to add a valid email as a chip
  void _addEmail() {
    String email = _emailController.text.trim();
    if (_isValidEmail(email) && !_selectedEmails.contains(email)) {
      setState(() {
        _selectedEmails.add(email);
        _emailController.clear();
        _currentInput = '';
      });
    }
  }

  // Email validation function
  bool _isValidEmail(String email) {
    // Regular expression to validate email format
    String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    return RegExp(emailPattern).hasMatch(email);
  }
}
