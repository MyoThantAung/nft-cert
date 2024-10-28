import 'package:flutter/material.dart';
import 'package:nft_cert/admin/event_settings.dart';
import 'package:nft_cert/user/request_fill.dart';

class UserEventCard extends StatelessWidget {
  final String orgId;
  final String cereId;
  final String eventName;
  final String organizationName;
  final bool verified;
  final bool available;
  final bool clickable;

  UserEventCard({
    required this.orgId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
    required this.clickable,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 0,
        bottom: 16,
      ),
      child: GestureDetector(
        onTap: () {
          if (clickable) {
// Navigate to EventScreen and pass the event data
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RequestFill(
                  orgId: orgId,
                  cereId: cereId,
                  eventName: eventName,
                  organizationName: organizationName,
                  verified: verified,
                  available: available,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 8, // Adjust the space for the left side content
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eventName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      eventName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      organizationName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
