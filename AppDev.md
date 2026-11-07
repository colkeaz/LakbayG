# TuDok(Tulong-Dokyumento)

## *Citizen-Centered Government Document Navigation Application*

Flutter \+ Dart \| Android-first proof of concept \| Proposal for faculty approval \| 15 October 2026

# **Project Overview**

LakbayGobyerno is an independent mobile guidance prototype that helps citizens identify the appropriate government service, processing location, documentary requirements and sequence of steps for selected government-issued documents. It organizes verified official guidance around a citizen’s need rather than assuming familiarity with agency structures.

# **Problem and Motivation**

A team member in Taal, Batangas, seeking an existing Certificate of Live Birth copy was directed to the wrong department, waited in a long queue and learned of the mistake only at the counter. A teammate from San Pablo, Laguna, had difficulty locating the relevant office for a clearance transaction (specific clearance type to be confirmed). These incidents motivate an investigation into service-location uncertainty, incorrect referrals and procedural navigation. They are illustrative experiences, not evidence of nationwide prevalence.

# **Objectives**

* Help a user distinguish between similar documentary services and find the responsible agency.  
* Present a verified, source-linked sequence of processing steps and locations for selected transactions.  
* Allow users to prepare and save a checklist of applicable requirements before visiting an office.

# **Three Core Functional Features**

**1\. Need-First Service Navigator —** A rule-based guided questionnaire maps a selected need to the appropriate service or advises official verification when information is insufficient.

**2\. Verified Process Roadmap —** Displays the responsible agency, verified service point, ordered procedure, official references and last-checked date.

**3\. Document Readiness Checklist —** Lets users mark required items as prepared, see missing items and retain checklist state locally.

# **Intended Users and Initial Scope**

Primary users are first-time or infrequent applicants, especially students unfamiliar with documentary-service processes. The prototype will cover only two or three transactions after verifying current official source materials; candidate pathways include a local civil-registry birth-record copy and either PNP or NBI clearance, which are separate services.

# **Implementation Feasibility**

Flutter and Dart with a local curated service dataset and persistent checklist storage (e.g., SQLite). Deterministic branching rules avoid speculative AI-generated legal or procedural advice. Government databases, real-time queue monitoring, fee collection and official appointment integration are not required.

# **Basis and Existing Systems**

Republic Act No. 11032 requires government offices to publish Citizen’s Charters describing requirements and procedures. Official sources already include local government service guides and national PNP, NBI and PSA channels. This proposal does not seek to replace those platforms; it tests a need-first navigation experience that links back to them.

# **Validation and Responsible Boundaries**

The team will cross-check every implemented step with current official material and test branching accuracy, error handling, mobile usability and local data persistence. Optional low-cost campus-based usability tasks may offer preliminary feedback. Guidance will show its source and last-verification date and clearly identify the application as a student project, not an official government service.

# **Expected Deliverable**

A working Android-first Flutter prototype demonstrating the three core functions with two or three verified sample service journeys, functional test evidence, and a concise source register.

# **Known Limitations**

The prototype cannot issue documents or guarantee that office assignments or requirements remain unchanged. Its value is improved preparation and transparent navigation; reducing real-world delays remains an evaluation hypothesis, not a proven outcome.

# **Reference Starting Points**

RA 11032: https\://lawphil.net/statutes/repacts/ra2018/ra\_11032\_2018.html \| ARTA: https\://arta.gov.ph/ \| PNP: https\://pnpclearance.ph/ \| NBI: https\://clearance.nbi.gov.ph/ \| PSA: https\://psa.gov.ph/ \| Taal: https\://news.taal.gov.ph/