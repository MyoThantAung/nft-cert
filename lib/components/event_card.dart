import 'package:flutter/material.dart';
import 'package:nft_cert/admin/event_settings.dart';

class EventCard extends StatelessWidget {
  final String orgId;
  final String cereId;
  final String eventName;
  final String organizationName;
  final bool verified;
  final bool available;
  final bool isClickable;

  EventCard({
    required this.orgId,
    required this.cereId,
    required this.eventName,
    required this.organizationName,
    required this.verified,
    required this.available,
    required this.isClickable,
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
          if (isClickable) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventSettingScreen(
                  orgId: orgId,
                  cereId: cereId,
                  eventName: eventName,
                  organizationName: organizationName,
                  verified: verified,
                ),
              ),
            );
          }
          // Navigate to EventScreen and pass the event data
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
                      cereId,
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
              SizedBox(width: 16), // Space between content and icon
              Expanded(
                flex: 2, // Adjust the space for the right side icon
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons
                        .article_outlined, // This is a similar icon to the one in the image
                    size: 25,
                    color: verified
                        ? available
                            ? Colors.blue
                            : Colors.green
                        : Colors.red, // Color to match the icon style
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
