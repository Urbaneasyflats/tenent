import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum LegalPolicyType { terms, privacy }

class LegalPolicyPage extends StatelessWidget {
  const LegalPolicyPage({super.key, required this.type});

  final LegalPolicyType type;

  String get _title => switch (type) {
        LegalPolicyType.terms => 'Terms & Conditions',
        LegalPolicyType.privacy => 'Privacy Policy',
      };

  String get _updatedAt => switch (type) {
        LegalPolicyType.terms => 'Last updated: 16-05-2026',
        LegalPolicyType.privacy => 'Effective Date: 16-10-2025',
      };

  List<_PolicySection> get _sections => switch (type) {
        LegalPolicyType.terms => _termsSections,
        LegalPolicyType.privacy => _privacySections,
      };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _updatedAt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  type == LegalPolicyType.terms
                      ? 'These Terms govern access to www.urbaneasyflats.com, the Urban EasyFlats mobile application, and all related property, rental, society, and payment services.'
                      : 'URBAN EASYFLATS AND HOMES PRIVATE LIMITED explains how it collects, uses, stores, shares, and protects personal information when you use the website, mobile application, or services.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ..._sections.map((section) {
            return _PolicySectionCard(section: section);
          }),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({required this.section});

  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...section.points.map((String point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      point,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.points});

  final String title;
  final List<String> points;
}

const List<_PolicySection> _termsSections = <_PolicySection>[
  _PolicySection(
    title: 'Urban Easyflats and Homes Private Limited',
    points: <String>[
      'Urban Easyflats and Homes Private Limited is hereinafter referred to as "Urban Easyflats", "Company", "We", "Us", or "Our".',
      'These Terms govern access to and use of www.urbaneasyflats.com, the mobile application, and all related services, collectively called the Platform.',
      'By accessing, browsing, or registering on the Platform, the user, visitor, resident, tenant, owner, or society member confirms that they have read, understood, and agreed to these Terms. If you do not agree, discontinue using the Platform immediately.',
    ],
  ),
  _PolicySection(
    title: '1. Introduction',
    points: <String>[
      'Urban Easyflats and Homes Private Limited is a technology-driven platform that provides property listing, rental management, digital tenancy agreements, society maintenance management, and payment processing services for property owners, tenants, and societies.',
      'These Terms may be changed or updated at any time without prior notice. Users are advised to revisit the Terms periodically. Continued use of the Platform implies acceptance of updated Terms.',
    ],
  ),
  _PolicySection(
    title: '2. Ownership and Use of Content',
    points: <String>[
      'All logos, marks, designs, graphics, names, software, and other intellectual property visible on the Platform are the property of Urban Easyflats and Homes Pvt. Ltd. or its licensed partners.',
      'No part of the Platform or its content may be copied, modified, republished, uploaded, posted, transmitted, or distributed without prior written consent from the Company.',
      'Users may download or print information from the Platform solely for personal and non-commercial purposes. Unauthorized use may result in civil or criminal liability.',
    ],
  ),
  _PolicySection(
    title: '3. Acceptable Use Policy',
    points: <String>[
      'Users are prohibited from accessing data or servers without authorization, testing or probing system vulnerability, introducing viruses or malicious code, interfering with Platform functionality, or sending spam or unsolicited advertising through the Platform.',
      'Users shall not upload defamatory, obscene, abusive, or unlawful content; violate intellectual property rights; harm or disrupt Platform integrity; impersonate another person; or misrepresent affiliation with any entity.',
      'Violation of these rules may lead to suspension of access, legal prosecution, or both.',
    ],
  ),
  _PolicySection(
    title: '4. Property and Society Management Services',
    points: <String>[
      'Urban Easyflats provides digital solutions for property listings and hosting, digital rent agreements, automated bill generation, payment processing, and society communication and management tools.',
      'The Company acts only as a technology intermediary and does not participate in rent negotiations, disputes, or personal transactions between users and third parties.',
    ],
  ),
  _PolicySection(
    title: '5. Rent and Maintenance Payment Terms',
    points: <String>[
      'Urban Easyflats offers users a secure platform to make rental and society maintenance payments through integrated third-party payment gateways.',
      'Urban Easyflats is not a financial institution and does not provide banking or escrow services. Its role is limited to facilitating payments between payers and beneficiaries, such as landlords or society associations.',
      'The user acknowledges that each transaction represents a valid payment based on an actual rent or maintenance agreement between the parties involved. The Company is not responsible for the underlying contractual relationship.',
    ],
  ),
  _PolicySection(
    title: '6. KYC and Verification',
    points: <String>[
      'To comply with legal and regulatory requirements, Urban Easyflats may request verification documents, including government-issued ID such as Aadhaar, PAN, Passport, rent or maintenance agreements, and proof of property ownership or tenancy.',
      'For transactions above Rs. 50,000 or as required by law, PAN and other supporting documents may be mandatory.',
      'Users consent to Urban Easyflats verifying submitted details through authorized sources or third-party APIs.',
    ],
  ),
  _PolicySection(
    title: '7. Payment Authorization',
    points: <String>[
      'By initiating a payment on the Platform, you authorize Urban Easyflats to process the payment through authorized gateways.',
      'You authorize transfer of funds to the designated beneficiary account as per your instructions and deduction of applicable convenience fees, service charges, or taxes, if any.',
      'If payment fails or details are incomplete or incorrect, the Company may refund the amount to the original source account after deducting applicable charges.',
    ],
  ),
  _PolicySection(
    title: '8. Transaction Terms and Responsibility',
    points: <String>[
      'Users must ensure accuracy while entering beneficiary bank details. Urban Easyflats will not be liable for payments credited to an incorrect account due to user error.',
      'Users are responsible for safeguarding login credentials and payment details. The Company will not be liable for unauthorized transactions resulting from negligence, password sharing, or device compromise.',
      'Urban Easyflats may delay, hold, or reject a payment if it appears suspicious, fraudulent, or in violation of these Terms.',
    ],
  ),
  _PolicySection(
    title: '9. Refunds, Reversals, and Chargebacks',
    points: <String>[
      'If a transaction fails due to technical issues on the Company side, the amount will be automatically refunded to the payer original payment source within the standard processing period.',
      'Once funds are successfully credited to the beneficiary account, no refund or reversal will be initiated by Urban Easyflats.',
      'Chargebacks or disputes raised with payment providers will be handled according to their policies. The beneficiary shall bear full responsibility for reversals or penalties.',
      'Users and beneficiaries must cooperate and provide all necessary documents for dispute resolution.',
    ],
  ),
  _PolicySection(
    title: '10. Fraud and Unauthorized Activity',
    points: <String>[
      'If you notice suspicious or unauthorized transactions, immediately notify Urban Easyflats at customersupport@urbaneasyflats.com.',
      'Urban Easyflats will take reasonable steps to prevent further unauthorized use but will not be liable for losses if payments have already been transferred as per details provided by the user.',
      'Users are solely responsible for maintaining confidentiality of login credentials and personal information.',
    ],
  ),
  _PolicySection(
    title: '11. Indemnity',
    points: <String>[
      'You agree to indemnify, defend, and hold harmless Urban Easyflats, its directors, officers, employees, and partners from any claim, damage, liability, or expense arising from misuse of the Platform.',
      'Indemnity also applies to breach of these Terms, disputes between you and another user, property owner, tenant, or society, and any legal or regulatory action related to your transactions.',
    ],
  ),
  _PolicySection(
    title: '12. Limitation of Liability',
    points: <String>[
      'Urban Easyflats shall not be liable for direct, indirect, incidental, or consequential damages arising from use or inability to use the Platform, delays or errors in payment processing, unauthorized access to data, or interruption, suspension, or termination of services.',
      'Total liability in any circumstance shall not exceed the total service fee paid by the user, if any, related to the disputed transaction.',
    ],
  ),
  _PolicySection(
    title: '13. Termination or Suspension',
    points: <String>[
      'The Company may suspend or terminate user access at any time if it suspects misuse, fraud, or violation of these Terms.',
      'Upon termination, all rights granted to the user will immediately cease.',
    ],
  ),
  _PolicySection(
    title: '14. Governing Law and Jurisdiction',
    points: <String>[
      'These Terms shall be governed and construed in accordance with the laws of India.',
      'Any disputes shall be subject exclusively to the jurisdiction of the courts of Hyderabad, Telangana.',
    ],
  ),
  _PolicySection(
    title: '15. Contact Information',
    points: <String>[
      'For concerns, disputes, or clarifications regarding these Terms, contact Urban Easyflats and Homes Private Limited.',
      'Email: customersupport@urbaneasyflats.com | info@urbaneasyflats.com',
      'Website: www.urbaneasyflats.com',
      'Address: D.NO: 1-57/272/C, SRI RAM NAGAR COLONY, KONDAPUR-500084, Hyderabad, Telangana, India.',
      'Copyright 2025 Urban Easyflats and Homes Private Limited. All rights reserved.',
    ],
  ),
  _PolicySection(
    title: '16. Platform Fee, Settlement, and Withdrawals',
    points: <String>[
      'Urban EasyFlats may charge a non-refundable Platform Service Fee, Booking Fee, Convenience Fee, Processing Fee, or Technology Usage Fee for access to the Platform, customer support, payment processing integrations, tenant onboarding, booking management, and related technology services.',
      'The Platform Service Fee is earned immediately upon successful booking, payment initiation, tenant confirmation, service request processing, or transaction completion on the Platform.',
      'The Platform Service Fee is strictly non-refundable under all circumstances, including tenant cancellation, change of mind, property rejection after booking, delay in occupancy, early vacating, non-utilization of services, payment gateway interruptions, technical issues not attributable to Urban EasyFlats, disputes between users, booking modifications, or user dissatisfaction after service access has been provided.',
      'The Platform Service Fee is separate from rent, security deposit, maintenance charges, utility charges, society dues, owner collections, refundable deposits, and third-party gateway charges.',
      'Urban EasyFlats facilitates payments through authorized third-party payment gateways, banking partners, financial institutions, and payment processors. Settlement timelines depend on banking operational hours, RBI guidelines, public holidays, weekend restrictions, payment gateway cycles, and technical availability.',
      'Rent payments made on Saturdays, Sundays, public holidays, bank holidays, festival holidays, non-working days, or after banking cut-off times may be reflected in the relevant wallet or bank account on the next working banking day.',
      'Maintenance payments and society dues follow the same banking and gateway settlement rules. Urban EasyFlats does not guarantee instant transfer during non-working banking periods.',
      'Wallet withdrawal requests initiated during weekends, holidays, festival days, bank holidays, or non-operational banking hours may be processed on the next working day. Actual bank credit timelines may vary by beneficiary bank, gateway clearance, and regulatory checks.',
      'Urban EasyFlats may temporarily hold, review, delay, or restrict withdrawals for fraud prevention, suspicious transaction review, chargeback investigation, or technical reconciliation.',
      'Urban EasyFlats is not liable for settlement delays, banking interruptions, delayed wallet updates, delayed withdrawals, gateway failures, or bank server downtime caused by third parties.',
      'By using the Platform, all users agree to these fee, settlement, and withdrawal timelines and acknowledge that Urban EasyFlats functions as a technology intermediary platform.',
    ],
  ),
];

const List<_PolicySection> _privacySections = <_PolicySection>[
  _PolicySection(
    title: 'Entity and Contact',
    points: <String>[
      'Entity: URBAN EASYFLATS AND HOMES PRIVATE LIMITED.',
      'Website: www.urbaneasyflats.com.',
      'Email: customersupport@urbaneasyflats.com.',
    ],
  ),
  _PolicySection(
    title: '1. Introduction',
    points: <String>[
      'URBAN EASYFLATS AND HOMES PRIVATE LIMITED, referred to as "Urban EasyFlats", "we", "our", or "us", respects your privacy and values your trust.',
      'This Privacy Policy explains how we collect, use, store, share, and protect personal information when you use the website, mobile application, or any services, collectively called the Platform.',
      'By accessing or using the Platform, you agree to this Privacy Policy. If you do not agree, discontinue use of the services immediately.',
    ],
  ),
  _PolicySection(
    title: '2. Scope of This Policy',
    points: <String>[
      'This Privacy Policy applies to users who access or register on the website or mobile application.',
      'It applies to property owners, tenants, societies, and agents using Urban EasyFlats for hosting, renting, or managing properties.',
      'It also applies to visitors interacting with services, forms, or customer support. It does not apply to external websites or services not owned or controlled by Urban EasyFlats.',
    ],
  ),
  _PolicySection(
    title: '3. Information We Collect',
    points: <String>[
      'Personal information may include full name, contact number, email address, property address, identity proofs, and payment details.',
      'Non-personal information may include device information, operating system, browser type, IP address, location data, app usage patterns, preferences, cookies, and analytics data.',
      'Most information is provided voluntarily during account creation, property hosting, service use, or communication with the support team.',
    ],
  ),
  _PolicySection(
    title: '4. Purpose of Data Collection',
    points: <String>[
      'Information is used to create and manage user accounts, enable hosting, renting, and property management operations, and generate digital rental agreements and bills.',
      'Information is used to send booking confirmations, alerts, due date reminders, service updates, and communications.',
      'Information is used to ensure property compliance, tenant verification, improve the Platform, develop new features, and communicate offers or announcements with consent where required.',
    ],
  ),
  _PolicySection(
    title: '5. Data Sharing and Disclosure',
    points: <String>[
      'Urban EasyFlats does not sell or rent personal data.',
      'Limited information may be shared with property owners or managers for verification and stay management when a user rents or resides in a listed property.',
      'Information may be shared with service providers such as payment gateways, verification partners, and analytics providers working under confidentiality obligations.',
      'Information may be disclosed when required by law, court order, government authority, fraud prevention, cyber incident response, or other unlawful activity prevention.',
    ],
  ),
  _PolicySection(
    title: '6. Your Rights and Choices',
    points: <String>[
      'You may access or review personal data stored with Urban EasyFlats.',
      'You may request correction or updates to your information.',
      'You may withdraw consent for promotional communications and request deletion of personal data, subject to applicable legal and operational requirements.',
      'To exercise these rights, contact customersupport@urbaneasyflats.com.',
    ],
  ),
  _PolicySection(
    title: '7. Data Retention and Deletion',
    points: <String>[
      'Urban EasyFlats retains personal information only for as long as required to provide services or comply with legal obligations.',
      'To delete an account and associated data, use profile settings in the app where available or send a request to customersupport@urbaneasyflats.com with the subject "Data Deletion Request".',
      'Upon verification, data will be permanently removed within a reasonable time frame unless retention is required by law.',
    ],
  ),
  _PolicySection(
    title: '8. Cookies and Tracking Technologies',
    points: <String>[
      'The Platform uses cookies and similar tools to enhance browsing experience.',
      'Cookies help recognize returning users, analyze usage trends, and personalize content and recommendations.',
      'Users can modify browser settings to disable cookies, but some services may not function optimally.',
    ],
  ),
  _PolicySection(
    title: '9. Data Security',
    points: <String>[
      'Urban EasyFlats follows technical and organizational measures to protect data against unauthorized access, alteration, or destruction.',
      'Security measures include encrypted data storage, restricted access control, and regular security audits.',
      'No online platform can guarantee complete protection, even though Urban EasyFlats strives for high security standards.',
    ],
  ),
  _PolicySection(
    title: '10. Third-Party Links',
    points: <String>[
      'The website or app may contain links to third-party websites or services.',
      'Urban EasyFlats is not responsible for the privacy practices or content of external sites and encourages users to review their respective privacy policies.',
    ],
  ),
  _PolicySection(
    title: '11. Updates to This Policy',
    points: <String>[
      'Urban EasyFlats may update or revise this Privacy Policy to reflect changes in practices, technologies, or legal requirements.',
      'The latest version will be available on the website with the effective date clearly mentioned.',
      'Continued use of services after changes means acceptance of the updated policy.',
    ],
  ),
  _PolicySection(
    title: '12. Grievance and Contact Information',
    points: <String>[
      'For concerns, complaints, or requests regarding personal information or this Privacy Policy, contact the Grievance Officer / Data Protection Officer.',
      'URBAN EASYFLATS AND HOMES PRIVATE LIMITED.',
      'Registered Office Address: D.NO: 1-57/272/C, SRI RAM NAGAR COLONY, KONDAPUR-500084, Hyderabad, Telangana, India.',
      'Email: customersupport@urbaneasyflats.com | info@urbaneasyflats.com | sales@urbaneasyflats.com.',
      'Website: www.urbaneasyflats.com.',
    ],
  ),
];
