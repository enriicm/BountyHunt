# Disclaimer — BountyHunt

## Authorized Use Only

BountyHunt is a security research tool designed exclusively for:

- **Bug bounty programs** where you have been explicitly authorized to test the target
- **Penetration testing engagements** with a signed Statement of Work or written authorization
- **CTF (Capture the Flag)** competitions on designated challenge infrastructure
- **Your own systems** that you own or operate
- **Controlled lab environments** built for security training

## Prohibited Use

The following uses are **strictly prohibited** and may constitute criminal offenses under computer fraud laws (including but not limited to the CFAA in the United States, the Computer Misuse Act in the UK, and equivalent legislation in other jurisdictions):

- Testing systems without **explicit written authorization** from the system owner
- Accessing, modifying, or exfiltrating data beyond the defined scope of an authorized engagement
- Using findings to extort, blackmail, or coerce any person or organization
- Conducting denial-of-service attacks or tests that degrade service availability
- Testing systems belonging to critical infrastructure (power grids, hospitals, financial systems) without appropriate clearance
- Sharing vulnerabilities publicly before responsible disclosure deadlines

## Scope Compliance

When working within a bug bounty program:

1. **Read the program policy** in full before testing
2. **Load the scope file** using BountyHunt's scope manager
3. **Verify in-scope status** before scanning any target
4. **Do not test out-of-scope assets** even if discovered during reconnaissance
5. **Report findings** through the program's official submission channels
6. **Follow disclosure timelines** as defined by the program

## No Warranty

This software is provided "as is," without warranty of any kind. The authors and contributors:

- Make no representations about the accuracy or completeness of findings
- Accept no liability for false positives or false negatives
- Are not responsible for any damage caused by the use or misuse of this tool
- Provide no guarantee of finding all vulnerabilities in a target

All findings from automated tools **must be manually verified** before submission to any bug bounty program.

## Data Handling

BountyHunt stores scan results locally in your output directory (`~/bountyhunt_results` by default). It is your responsibility to:

- Protect scan data containing potentially sensitive information
- Delete scan data when no longer needed
- Not share scan data with unauthorized parties
- Comply with applicable data protection regulations

## Responsibility

By using BountyHunt, you accept full responsibility for:

- Obtaining proper authorization before any scan
- Compliance with all applicable laws and regulations in your jurisdiction
- The consequences of any unauthorized or improper use
- Any damage caused by running this tool against a target

**If you are unsure whether you are authorized to test a target, you are not authorized. Do not proceed.**

---

*The authors and contributors of BountyHunt do not condone illegal activity. This tool is built for the security community to do better, more precise, authorized work.*
