import 'package:flutter_test/flutter_test.dart';
import 'package:resident_app/src/core/models/api_models.dart';

void main() {
  group('NotificationData', () {
    test('normalizes backend notification types to business categories', () {
      final Map<int, String> expectedTypes = <int, String>{
        1: 'billing',
        2: 'contract',
        3: 'announcement',
        4: 'support',
        5: 'billing',
        6: 'enquiry',
        7: 'system',
      };

      for (final MapEntry<int, String> entry in expectedTypes.entries) {
        final NotificationData notification = NotificationData.fromJson(
          <String, dynamic>{
            'Vendor_NotificationID': 'notification-${entry.key}',
            'Title': 'Notification',
            'Message': 'Message',
            'Notification_Type': entry.key,
            'createdAt': '2026-05-13T10:00:00.000Z',
          },
        );

        expect(notification.type, entry.value);
      }
    });

    test('keeps reference and payload details from backend response', () {
      final NotificationData notification = NotificationData.fromJson(
        <String, dynamic>{
          'Vendor_NotificationID': 'notification-1',
          'Title': 'New Property Enquiry',
          'Message': 'A tenant enquired about your property.',
          'Notification_Type': 6,
          'Reference_Type': 'Property_Enquiry',
          'Reference_ID': 'enquiry-1',
          'Whether_Read': true,
          'createdAt': '2026-05-13T10:00:00.000Z',
          'Data': <String, dynamic>{
            'Name': 'Raj',
            'PhoneNumber': '9000000000',
            'Property_Title': 'Green Nest PG',
            'Property_Type': 3,
            'Property_Type_Label': 'PG',
            'Sub_Type': 1,
            'Sub_Type_Label': 'Mens PG',
            'PG_Sharing_Type': 2,
            'PG_Sharing_Type_Label': 'Double Sharing',
          },
        },
      );

      expect(notification.type, 'enquiry');
      expect(notification.referenceType, 'Property_Enquiry');
      expect(notification.referenceId, 'enquiry-1');
      expect(notification.data['Name'], 'Raj');
      expect(notification.data['Property_Type_Label'], 'PG');
      expect(notification.data['Sub_Type_Label'], 'Mens PG');
      expect(notification.data['PG_Sharing_Type_Label'], 'Double Sharing');
      expect(notification.isRead, isTrue);
    });
  });
}
