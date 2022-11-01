<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
<!-- [![LinkedIn][linkedin-shield]][linkedin-url]-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/astubenbord/paperless-mobile">
    <img src="assets/logos/paperless_logo_green.png" alt="Logo" width="80" height="80">
  </a>

<h3 align="center">Paperless Mobile</h3>

  <p align="center">
    An (almost) fully fledged mobile paperless client.
    <br />
    <br />
    <!--<a href="https://github.com/astubenbord/paperless-mobile">View Demo</a>
    ·-->
    <a href="https://github.com/astubenbord/paperless-mobile/issues">Report Bug</a>
    ·
    <a href="https://github.com/astubenbord/paperless-mobile/issues">Request Feature</a>
  </p>
</div>

<!-- ABOUT THE PROJECT -->
## About The Project
With this app you can conveniently add, manage or simply find documents stored in your paperless server without any comproimises. This project started as a small fun side project to learn more about the Flutter framework and because existing solutions didn't fulfill my needs, but it has grown much faster with far more features than I originally anticipated.  


### :rocket: Features
:heavy_check_mark: **View** your documents at a glance, in a compact list or a more detailed grid view<br>
:heavy_check_mark: **Add**, **delete** or **edit** your documents<br>
:heavy_check_mark: **Share**, **download** and **preview** PDF files<br>
:heavy_check_mark: **Manage** and assign correspondents, document types, tags and storage paths<br>
:heavy_check_mark: **Scan** and upload documents with preset correspondent, document type, tags and creation date<br>
:heavy_check_mark: **Search** for documents using a wide range of filter criteria<br>
:heavy_check_mark: **Secure** your data with **biometric authentication** across sessions<br>
:heavy_check_mark: Support for **TLS mutual authentication** (client certificates)<br>
:heavy_check_mark: **Modern, intuitive UI** built according to the Material Design 3 specification<br>
:heavy_check_mark: Available in english and german language (more to come!)


### Built With

[![Flutter][Flutter]][Flutter-url]


<!-- GETTING STARTED -->
## Getting Started

To get a local copy up and running follow these simple steps.

### Prerequisites

* Install the Flutter SDK (https://docs.flutter.dev/get-started/install)
* Install an IDE of your choice (e.g. VSCode with the Dart/Flutter extensions)

### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/astubenbord/paperless-mobile.git
   ```
2. Install the dependencies (should be done automatically by your IDE) and generate localization files
   ```sh
   flutter pub get
   ```
3. Build generated files (e.g. for injectable library)
   ```sh
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

<!-- ROADMAP -->
## Roadmap
- [x] Add download functionality (implemented, but flutter cannot download to useful directories except app directory)
- [x] Add document share support
- [x] Improvements to UX (e.g. form fields show clear button while empty)
- [ ] Add more languages
- [ ] Support for IOS
- [ ] Automatic releases and CI/CD with fastlane
- [ ] Templates for recurring scans (e.g. monthly payrolls with same title, dates at end of month, fixed correspondent and document type)
- [ ] Custom document scanner optimized for common white A4 documents (currently using edge_detection, which is okay but not optimal for this use case)
- [ ] Support multiple instances (low prio)

See the [open issues](https://github.com/astubenbord/paperless-mobile/issues) for a full list of proposed features (and known issues).

<!-- CONTRIBUTING -->
## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.
All bug reports or feature requests are welcome, even if you can't contribute code!

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request


<!-- LICENSE -->
## License

Distributed under the GNU General Public License v3.0. See `LICENSE.txt` for more information.


<!-- USAGE EXAMPLES -->
## Screenshots
Here are some impressions from the app!

#### Login Page
<img src="https://user-images.githubusercontent.com/79228196/198392006-f3badfb3-17c7-4b46-91c7-595c93b146b7.png" width=200/> <img src="https://user-images.githubusercontent.com/79228196/198392041-1ef5de1e-7d26-47f6-bdfb-f5ac831ddb30.png" width=200/>

#### Documents Overview (List)
<img src="https://user-images.githubusercontent.com/79228196/198392750-a0e4c0b1-9c1c-4346-980a-64d1cc192a99.png" width=200> <img src="https://user-images.githubusercontent.com/79228196/198392767-995536e4-5737-476a-9e78-34c37fac9c60.png" width=200>

#### Documents Overview (Grid)
<img src="https://user-images.githubusercontent.com/79228196/198393000-83a32969-c0d8-4f81-bb20-8afc79057d62.png" width=200> <img src="https://user-images.githubusercontent.com/79228196/198393018-2f1d02fc-a410-45d8-a022-32c0ae377717.png" width=200>

#### Document Filter/Search (More filters below!)
<img src="https://user-images.githubusercontent.com/79228196/198393168-60aa5114-85a8-4def-9ca9-5374e0b92aef.png" width=200> <img src="https://user-images.githubusercontent.com/79228196/198393173-db38e99e-f408-4a31-bc6a-fcce91a2a900.png" width=200>

#### Document Details
<img src="https://user-images.githubusercontent.com/79228196/198393856-6b11dbdc-77ce-44e8-a69c-b0a2536cd38b.png" width=200> <img src="https://user-images.githubusercontent.com/79228196/198393867-39e2148e-53a7-4fc9-8b6d-2ab038dfea64.png" width=200>

#### Edit Document
<img src="https://user-images.githubusercontent.com/79228196/198393926-1adc3fe8-6981-4b20-854e-6d17611a1d7a.png" width=200><img src="https://user-images.githubusercontent.com/79228196/198393931-c3b214db-e96e-4da4-8327-9c4779c2c64a.png" width=200>

#### Scan
<img src="https://user-images.githubusercontent.com/79228196/198394782-0955a57b-90c6-4c42-946c-ecf5f94bf704.png" width=200><img src="https://user-images.githubusercontent.com/79228196/198394796-cc7a5bb3-81b4-4010-9444-33440eb9aef7.png" width=200>

#### Upload
<img src="https://user-images.githubusercontent.com/79228196/198394876-7438dcfe-d901-4ac8-8e7f-0eba7c72a5d7.png" width=200><img src="https://user-images.githubusercontent.com/79228196/198394883-2721211b-17dc-405b-9ee9-2ca943e630fa.png" width=200>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/astubenbord/paperless-mobile.svg?style=for-the-badge
[contributors-url]: https://github.com/astubenbord/paperless-mobile/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/astubenbord/paperless-mobile.svg?style=for-the-badge
[forks-url]: https://github.com/astubenbord/paperless-mobile/network/members
[stars-shield]: https://img.shields.io/github/stars/astubenbord/paperless-mobile.svg?style=for-the-badge
[stars-url]: https://github.com/astubenbord/paperless-mobile/stargazers
[issues-shield]: https://img.shields.io/github/issues/astubenbord/paperless-mobile.svg?style=for-the-badge
[issues-url]: https://github.com/astubenbord/paperless-mobile/issues
[license-shield]: https://img.shields.io/github/license/astubenbord/paperless-mobile.svg?style=for-the-badge
[license-url]: https://github.com/astubenbord/paperless-mobile/blob/main/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/linkedin_username
[product-screenshot]: images/screenshot.png
[Flutter]: https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white
[Flutter-url]: https://flutter.dev

