# ScholarSphere Policies

<p class="alert alert-info">
  For questions and concerns related to these policies, please <a href="/contact">contact us</a>
</p>

## Table of Contents
  - [Content & Deposit Policy](#content--deposit-policy)
    - [Requirements for Deposit](#requirements-for-deposit)
    - [Data Size Limits](#data-size-limits)
    - [Versioning](#versioning)
    - [Withdrawal and Deletion](#withdrawal-and-deletion)
    - [Retractions](#retractions)
  - [Access Policy](#access-policy)
    - [Work Visibility (Public vs. Penn State)](#work-visibility-public-vs-penn-state)
    - [Embargoes](#embargoes)
  - [Curation Policy](#curation-policy)
  - [Preservation Policy](#preservation-policy)
    - [Storage & Backup](#storage--backup)
    - [Repository Closure](#repository-closure)
    - [URLs & Persistent Identifiers](#urls--persistent-identifiers)

## Content & Deposit Policy

### Requirements for Deposit
To be eligible for deposit in ScholarSphere, works must:

-	Be produced or sponsored by at least one member of the Penn State community;
-	Be of scholarly import, including publications, instructional materials, creative works, and research data produced in support of Penn State's teaching, learning, and research mission; and
-	Meet the requirements of [Penn State Policy AD69 Accessibility of Electronic and Information Technology](https://policy.psu.edu/policies/ad69). 

Information with a Sensitive Information Classification of Moderate (Level 2) or higher according to [Penn State Policy AD95 Information Assurance and IT Security](https://policy.psu.edu/policies/ad95) is not permitted in ScholarSphere. Examples of sensitive information that should not be deposited include:

-	Social Security Numbers (SSNs), credit card numbers, bank account numbers, Driver's License numbers, state ID numbers, passport numbers, biometric data (including fingerprints, retina/facial images, and human DNA profile), birth dates, or protected health information
-	Works containing specific locations of endangered plants and animals or protected archaeological sites

The depositor must be able to grant to Penn State a non-exclusive license to reproduce, adapt, publicly distribute, publicly display, and publicly perform the work, subject to the access permissions selected by the depositor, as stated in the Depositor’s Agreement. The depositor must also be able to represent to Penn State that the deposit is not libelous or otherwise unlawful. If the depositor is not able to grant this license and make these warranties to Penn State, the content must not be deposited in ScholarSphere.
The deposited materials may be freely deposited and distributed elsewhere, in venues such as disciplinary data repositories, electronic journals, pre-print archives, conference proceedings, or course/learning management systems. Please consult the Depositor’s Agreement for clarification. 

As part of the deposit process, the depositor will be prompted to describe the content that is being deposited. The depositor will have the opportunity to apply one of the [Creative Commons licenses or a rights statement to the deposit](https://creativecommons.org/use-remix/cc-licenses/).

### Data Size Limits
Deposits larger than 100 GB in size require approval from repository managers in Penn State Libraries. This limit applies to the total size of files in a work or in a collection of related works by the same depositor. The Libraries may delete deposits over this threshold that have not received approval (see Withdrawal and Deletion).

To request approval for depositing large dataset, please contact: [repub@psu.edu](mailto:repub@psu.edu)

### Versioning
ScholarSphere deposits (“works”) consist of one or more versions. A work version may be in a “draft”, “published”, or “withdrawn” state. In the draft state, depositors may edit and remove metadata and files associated with the version. Once a version is published, it can no longer be modified by the depositor. To make changes, depositors may create and publish a new version of the work with updated files or metadata. The authoritative (or active) version of a work is the most recently published version. More information about the versioning system is available in the ScholarSphere technical documentation.

### Withdrawal and Deletion
Deposited (“published”) files and metadata may only be withdrawn or deleted under certain circumstances and by repository administrators in Penn State University Libraries. If any content that does not meet the requirements for deposit is found in ScholarSphere, the content will be withdrawn by the Libraries and may be permanently deleted. Additional circumstances in which content may be removed from ScholarSphere are outlined in the Preservation Policy.

When content is withdrawn, associated files are no longer accessible to the public or the Penn State community, however the content’s metadata remains accessible. This means the webpage for a withdrawn work version still exists, however the files associated with the work version will not be downloadable. Files associated with a withdrawn work version may be accessed by the depositors and repository administrators. When content is deleted, it is no longer accessible, even by the depositor. 

The Penn State University Libraries will attempt to notify depositors if their content is withdrawn or deleted. Notice will be attempted before content is deleted or after content is withdrawn.
Depositors may request that their content be withdrawn, but withdrawal will be done at the discretion of the Penn State University Libraries.

### Retractions
Authors are encouraged to notify ScholarSphere managers in the event that their publications or datasets are retracted. If a work on ScholarSphere is the subject of a retraction, a note indicating the retraction will be added to the work’s record. The Libraries may withdraw work that is subject to retraction.

## Access Policy

### Work Visibility (Public vs. Penn State)
Depositors assign a visibility setting to their deposited work that determines whether files are accessible to the public or only to users logged-in with a PSU account.

- Public Visibility: Published files can be accessed by anyone.
- Penn State Visibility: Published files are only accessible to users logged-in with a Penn State Access ID. 

The metadata record for a published work is publicly accessible regardless of visibility setting. This means the web page for a work with Penn State Visibility is public and it may appear in search results, however the work’s published files can only be downloaded by users logged-in with their Penn State Access ID.

### Embargoes
Depositors may publish their work under an embargo (up to 48 months). During the embargo period, metadata records of the work's published versions are publicly accessible, however the associated files are restricted. (The web page for the work is public, but the files will not be downloadable). When the embargo expires, the files are accessible according to the work's visibility settings as described above.

## Curation Policy

Penn State Librarians may request and perform changes to deposited materials, including files and metadata, in order to improve their long-term value and potential for reuse. Generally, curators work with depositors to make their work findable, accessible, interoperable and reusable ([FAIR](https://doi.org/10.5281/zenodo.3251593)). Penn State Librarians may refer to specialists outside of Penn State to guide the curation of work deposited to ScholarSphere.
Some curation actions are completed by the depositor or require permission from the depositor. These include changes such as:

- Renaming, reorganizing, or making changes to deposited files
- Creating and revising documentation files, such as READMEs

In order to improve discoverability and accessibility of deposited content over the long term, Penn State Libraries may perform the following actions without permission from the depositor: 

- correct and enhance metadata of deposited works (for example, the title, abstract, keywords, and publication date, as entered in the deposit form) in order to more accurately describe the work
- create and make available derivatives of deposited files in open, non-proprietary file formats (without affecting the content of the deposited files)
- migrate content to new versions of ScholarSphere or its successor repository.

## Preservation Policy
Deposited files and metadata are generally retained for the lifetime of the repository, however the guaranteed minimum preservation timeframe for work deposited to ScholarSphere is ten years. After that period, the Libraries may remove content that does not warrant continued preservation.
In addition, files and metadata will be permanently deleted from the repository if:

- required by law or University Policy
- the files or metadata do not conform with the Content and Deposit Policy (see “Content and Deposit Policy”)

ScholarSphere supports bit-level preservation of deposited content. All deposited files are stored with a checksum of the file content. ScholarSphere makes no promises of usability and understandability of deposited objects over time.

### Storage & Backup
Uploaded files are stored through a third-party service provider (currently, Amazon Web Services S3) and replicated across two geographic regions. Backups are generated on a daily basis and stored on Amazon Glacier. To ensure bit-level integrity, all data files are stored with a checksum of the file content. Metadata is stored in Penn State University Data Centers with daily backups. 

### Repository Closure
In the event of ScholarSphere’s closure, best efforts will be made to migrate all content to suitable alternative institutional and/or subject based repositories and to update persistent identifiers (DOIs) with new resource locations

### URLs & Persistent Identifiers
ScholarSphere does not guarantee the long-term stability of URLs to the repository domain (scholarsphere.psu.edu). Users who require a stable identifier for their deposited work should create a DOI for the work. More information on DOIs is available in the ScholarSphere user guide. 
