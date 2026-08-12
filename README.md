# Analisis Kinerja Bisnis E-Commerce Menggunakan SQL dan Python (Olist Dataset)

**End-to-end Marketplace Analysis Using SQL and Python (Olist Dataset)**


## Overview

Project ini akan melakukan analisis transaksi platform e-commorce Olist (Brazil) menggunakan SQL untuk data preparation dan agregasi, serta Python untuk analisis statistik dan visualisasi. Project ini akan menjawab 4 *business question* seputar tren transaksi, performa kategori produk, pengaruh keterlambatan pengiriman terhadap kepuasan pelanggan, dan segmentasi pelanggan.

**Tools:** MySQL Workbench (SQL) · Python (pandas, matplotlib, seaborn, scipy)


## Executive Summary

Analisis data transaksi Olist pada periode 2016 – 2018 menunjukkan bahwa GMV (total transaksi dalam platform) dan jumlah order meningkat pesat sepanjang 2017 dan kemudian relatif stabil pada selama 2018. Pola ini menunjukkan adanya pertumbuhan aktivitas transaksi dalam platform Olist.

Dari sisi customer experience, kategori produk cama_mesa_banho (perlengkapan rumah tangga) dan informatica_acessorios (aksesoris komputer) memiliki volume transaksi dan GMV yang tinggi, tetapi memiliki review score di bawah rata-rata keseluruhan (4,08), sehingga menjadi kategori produk yang perlu menjadi perhatian. Selain itu, semakin lama keterlambatan pengiriman, semakin rendah review score, menunjukkan hubungan yang konsisten antara delivery performance dan customer satisfaction.

Dari sisi customer value, Loyal Customers merupakan segmen terbesar dan menyumbang sebagian besar GMV, sementara Champions yang hanya mencakup 11,34% pelanggan menyumbang 27,03% GMV dengan rata-rata spend tertinggi. Temuan-temuan ini memberikan gambaran mengenai kategori produk, proses pengiriman, dan segmen pelanggan yang perlu menjadi perhatian dalam meningkatkan kinerja marketplace.

>**Catatan istilah:** Metrik **GMV** (Gross Merchandise Value), digunakan dalam laporan project ini karena data merepresentasikan total nilai transaksi yang mengalir di platform (harga barang dari seller), bukan pendapatan aktual Olist sebagai penyedia platform.


## Key Metrics

| **Metric**               | **Value**           |
|--------------------------|---------------------|
| Total GMV                | R$13.221.498,11 |
| Total orders (delivered) | 96.478           |
| Average GMV per order    | R$137,04         |
| Average review score     | 4,08             |
| On-time delivery rate    | 93,23%           |
| Repeat customer rate     | 3,00%            |
| Review coverage rate     | 99,33%           |


## Business Questions

1.  Bagaimana tren dan pertumbuhan GMV bulanan pada Olist?
2.  Kategori produk apa yang memiliki volume penjualan/GMV tinggi tetapi memiliki review score rendah sehingga memerlukan perhatian?
3.  Apakah keterlambatan pengiriman berpengaruh signifikan terhadap kepuasan pelanggan?
4.  Bagaimana segmentasi pelanggan berdasarkan Recency, Frequency, Monetary (RFM), dan segmen mana yang berisiko churn?


## Dataset

- **Sumber:** Olist E-Commerce Dataset (Kaggle)
- **Periode data:** September 2016 – Agustus 2018
- **Jumlah order:** 99.441 \| **Jumlah order delivered:** 96.478
- **Tabel yang digunakan:** orders, order_items, order_reviews, order_payments, customers, products


## Data Quality Notes & Decisions

| **Temuan**                                                         | **Keputusan**                                                              | **Alasan**                                                                          |
|--------------------------------------------------------------------|----------------------------------------------------------------------------|-------------------------------------------------------------------------------------|
| ~3% order berstatus non-delivered (canceled/shipped/dll)           | Analisis fokus pada status order delivered                                 | Merepresentasikan transaksi yang benar-benar selesai                                |
| Bulan September – Desember 2016 memiliki volume order sangat kecil | Dikecualikan dari perhitungan growth rate bulanan                          | Base data terlalu kecil sehingga dapat membuat growth % menyesatkan                 |
| 8 order delivered tanpa delivered_cutomer_date                     | Exclude khusus dari analisis delivery delay (BQ3)                          | Data entry error, dampak minimal (<0,01%)                                      |
| 547 order direview lebih dari sekali (2-3 kali)                    | Mengambil review terakhir per order (ROW_NUMBER() + PARTITION BY order_id) | Merepresentasikan kepuasan akhir customer dan menghindari duplikasi saat join table |
| 775 order tanpa order_items                                        | Otomatis ter-exclude karena semua berstatus non-delivered                  | GMV tidak dapat dihitung                                                            |
| 646 order delivered tanpa review                                   | Tetap digunakan pada analisis GMV dan exclude khusus pada analisis review  | Review bersifat opsional                                                            |


## Metodologi
1.  **Data preparations (SQL):** Eksplorasi struktur data, pengecekan missing value/duplikasi, pembuatan view bersih (vw_delivered_orders, vw_delivery_delay, vw_order_reviews_clean) sebagai basis seluruh analisis.
2.  **Business Analysis (SQL):** Query agregasi dan join multi tabel untuk menjawab tiap business question, memanfaatkan CTW, window function (LAG, NTILE, ROW_NUMBER).
3.  **Statistical analysis & visualization (Python):** Uji korelasi dan t-test untuk memvalidasi temuan secara statistik, visualisasi tren, segmentasi customer berbasis RFM score.


## Key Findings
### 1. Tren GMV

<p align="center">
  <img 
    src="https://github.com/user-attachments/assets/962a4024-289c-4a60-bdc5-7d684c5d4c50"
    width="600"
  />
</p>

GMV menunjukkan pertumbuhan yang kuat sepanjang 2017, meningkat dari sekitar R\$111,8 ribu pada bulan Januari menjadi R\$987,8 ribu pada bulan November, sejalan dengan peningkatan jumlah order dari 750 menjadi 7.289. lonjakan terbesar terjadi pada bulan November 2017 dengan pertumbuhan mencapai 52,37% yang bertepatan dengan periode Black Friday, sebelum turun sebesar 26,50% pada bulan Desember 2017. Pada tahun 2018, GMV kemudian relatif stabil pada kisaran R\$826-978 ribu tiap bulan, tanpa pertumbuhan sekuat tahun sebelumnya.

**Key findings:**
- 2017 merupakan periode utama pertumbuhan GMV dan jumlah order
- Lonjakan pada bulan November menunjukkan adanya pola musiman/promosional yang perlu diantisipasi
- GMV tetap tinggi pada tahun 2018, tetapi pertumbuhannya mulai melambat


### 2. Performa Ketegori Produk

<p align="center">
  <img width="546" height="108" alt="image2" src="https://github.com/user-attachments/assets/705e1ba5-de59-40e8-a05e-d6c3ab5b3b45" />
</p>

<table>
  <tr>
    <td><img width="100%" alt="image3" src="https://github.com/user-attachments/assets/a5b29e2e-1d42-432d-8fc3-de33ae520f9a"></td>
    <td><img width="100%" alt="image4" src="https://github.com/user-attachments/assets/585718ef-6af6-4f6c-b381-869b7c6f01c9" ></td>
  </tr>
</table>

Analisis menunjukkan bahwa kategori produk cama mesa banho (perlengkapan rumah tangga seperti perlengkapan kamar, meja, dan perlengkapan kamar mandi) serta informatica acessorios (aksesoris komputer) memiliki volume penjualan dan GMV yang tinggi, tetapi memiliki review score yang masih berada di bawah rata rata (4,1/5). Kategori produk perlengkapan kamar dan kamar mandi memiliki volume penjualan sebesar 10.831 items dengan GMV sekitar R\$1,01 juta, tetapi review score hanya 3,92/5. Sementara itu, kategori aksesoris komputer mencatat penjualan sebanyak 7.608 items, GMV R\$884,8 ribu, dan review score 3,99/5. Dengan harga rata-rata yang relatif rendah, tingginya GMV kedua kategori tersebut didorong oleh tingginya volume transaksi.

**Key findings:**
- Perlengkapan rumah tangga menjadi kategori yang paling perlu diperhatikan karena memiliki volume transaksi terbesar sekaligus review score yang rendah.
- Aksesoris komputer menunjukkan pola serupa, demand tinggi tetapi customer satisfaction masih di bawah rata-rata.
- Kedua kategori tersebut layak menjadi fokus *monitoring customer experience* dan *seller performance*.


### 3. Keterlambatan Pengiriman vs Kepuasan Pelanggan

<p align="center">
<img width="600" alt="image7" src="https://github.com/user-attachments/assets/ea7a1216-fd03-4c45-bd1b-315a99990946" />
</p>

Review score menunjukkan pola penurunan yang konsisten seiring meningkatnya keterlambatan pengiriman. Rata-rata score review turun dari **4,29 untuk order yang datang lebih awal** menjadi **4,03 untuk order yang tepat waktu**, kemudian **3,51**, **2,47**, hingga **1,72** pada order yang terlambat lebih dari lima hari. Pola ini menunjukkan bahwa semakin lama keterlambatan pengiriman, semakin rendah tingkat kepuasan pelanggan. Hasil korelasi pearson mendukung pola tersebut dengan hubungan negatif antara delivery delay dan review score (**r = -0,267; p \< 0,001**). Selain itu hasil uji dengan *t-test*, menunjukkan bahwa order yang terlambat memiliki review score yang lebih rendah dibandingkan order yang dikirim tepat waktu (**p \< 0,001**).

**Key findings**
- Semakin lama keterlambatan, semakin rendah review score.
- Delivery performance berpengaruh terhadap *customer satisfaction*.
- Keterlambatan menjadi salah satu aspek yang perlu diperhatikan untuk menjaga customer satisfaction


### 4. Segmentasi Pelanggan

Dalam project ini segmentasi pelanggan dilakukan dengan pendekatan RFM (recency, frequency, monetary) untuk melihat perilaku dan nilai pelanggan berdasarkan riwayat transaksi. Recency menunjukkan seberapa baru pelanggan melakukan pembelian, Frequency menunjukkan seberapa sering pelanggan bertransaksi, sedangkan Monetary menunjukkan total nilai transaksi pelanggan.

Masing-masing metrik kemudian diberikan score 1-4 (diperoleh dari pembagian data transaksi ke dalam 4 kelompok kuartil), kemudian score dari ketiga metrik tersebut dijumlahkan untuk membentuk rfm_score dengan rentang 3-12. Berdasarkan kombinasi score tersebut, pelanggan dikelompokkan menjadi empat segmen yaitu, Champions, Loyal Customers, Potential Loyalist, dan At Risk / Lost.

<p align="center">
<img width="600" alt="image9" src="https://github.com/user-attachments/assets/7ebed313-7705-4e74-bc55-bf8a59f1f4e7" />
</p>

Segmentasi RFM menunjukkan bahwa Loyal Customers merupakan segmen terbesar yang mencakup 62,53% pelanggan serta menyumbang 63,46% dari total GMV dengan average spend sebesar R\$143,7. Sementara itu, segmen Champions hanya mencakup 11,34% pelanggan tetapi menyumbang 27,03% GMV, dengan average spend R\$337,63, lebih dari dua kali average spend Loyal Customers. Di sisi lain, At Risk/Lost dan Potential Loyalist mencakup sekitar 26% pelanggan, tetapi hanya menyumbang 9,52% GMV.

**Key findings**

- Segmen Champions hanya mencakup 11,34% pelanggan, tetapi menyumbang 27,03% GMV dengan rata rata spend sebesar R\$337,63
- Sebagian besar pelanggan berada pada segmen Loyal Customers, tetapi rata rata spend pelanggan masih jauh lebih rendah dibanding segmen Champions.


## Business Recommendations

1.  **Melakukan monitor performa seller pada kategori dengan volume transaksi tinggi tetapi review score rendah,** terutama pada kategori perlengkapan rumah tangga dan aksesoris komputer untuk mengidentifikasi sumber masalah *customer experience.*
2.  **Memperbaiki proses logistik,** karena delay terbukti menurunkan kepuasan pelanggan
3.  **Rancang program retensi pelanggan,** karena tingkat pembelian ulang masih rendah (hanya 3% pelanggan) dan sebagian besar GMV berganung pada segmen champions yang kecil. Sehingga Olist dapat membuat program loyalty/reward untuk mendorong pelanggan lain terutama pada segmen potential loyalist agar lebih sering berbelanja kembali
4.  **Manfaatkan pola musiman seperti black Friday** dengan mereplikasi strategi promosi yang berpotensi mendorong GMV pada event besar lainnya, serta mempersiapkan kapasitas seller dan fulfillment untuk mengantisipasi lonjakan pesanan dan menjaga ketepatan waktu pengiriman.


## Skills

SQL · Python · Statistical Analysis · RFM Segmentation · Data Quality Validation · Business Analysis

