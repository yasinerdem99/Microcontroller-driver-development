<?xml version="1.0" encoding="UTF-8"?>
<ui version="4.0">
 <class>MainWindow</class>
 <widget class="QMainWindow" name="MainWindow">
  <property name="geometry">
   <rect>
    <x>0</x>
    <y>0</y>
    <width>1096</width>
    <height>752</height>
   </rect>
  </property>
  <property name="windowTitle">
   <string>MainWindow</string>
  </property>
  <widget class="QWidget" name="centralwidget">
   <widget class="QGroupBox" name="groupBox">
    <property name="geometry">
     <rect>
      <x>0</x>
      <y>0</y>
      <width>431</width>
      <height>121</height>
     </rect>
    </property>
    <property name="title">
     <string>Bağlantı Ayarları</string>
    </property>
    <widget class="QComboBox" name="comboBox">
     <property name="geometry">
      <rect>
       <x>0</x>
       <y>20</y>
       <width>201</width>
       <height>41</height>
      </rect>
     </property>
    </widget>
    <widget class="QComboBox" name="baudRateComboBox">
     <property name="geometry">
      <rect>
       <x>0</x>
       <y>70</y>
       <width>201</width>
       <height>41</height>
      </rect>
     </property>
    </widget>
    <widget class="QPushButton" name="baglanButton">
     <property name="geometry">
      <rect>
       <x>230</x>
       <y>20</y>
       <width>181</width>
       <height>41</height>
      </rect>
     </property>
     <property name="text">
      <string>Bağlantı Kur</string>
     </property>
    </widget>
    <widget class="QPushButton" name="baglantiKesButton">
     <property name="geometry">
      <rect>
       <x>230</x>
       <y>70</y>
       <width>181</width>
       <height>41</height>
      </rect>
     </property>
     <property name="text">
      <string>Bağlantı Kes</string>
     </property>
    </widget>
   </widget>
   <widget class="QGroupBox" name="groupBox_2">
    <property name="geometry">
     <rect>
      <x>0</x>
      <y>130</y>
      <width>431</width>
      <height>161</height>
     </rect>
    </property>
    <property name="title">
     <string>Kanal ve Akım Ayarı</string>
    </property>
    <widget class="QSpinBox" name="spinBox">
     <property name="geometry">
      <rect>
       <x>10</x>
       <y>30</y>
       <width>191</width>
       <height>41</height>
      </rect>
     </property>
     <property name="maximum">
      <number>6</number>
     </property>
    </widget>
    <widget class="QDoubleSpinBox" name="doubleSpinBox">
     <property name="geometry">
      <rect>
       <x>10</x>
       <y>80</y>
       <width>191</width>
       <height>51</height>
      </rect>
     </property>
     <property name="minimum">
      <double>-20.000000000000000</double>
     </property>
     <property name="maximum">
      <double>20.000000000000000</double>
     </property>
    </widget>
    <widget class="QPushButton" name="gonderButton">
     <property name="geometry">
      <rect>
       <x>230</x>
       <y>40</y>
       <width>171</width>
       <height>91</height>
      </rect>
     </property>
     <property name="text">
      <string>GONDER</string>
     </property>
    </widget>
   </widget>
   <widget class="QGroupBox" name="groupBox_3">
    <property name="geometry">
     <rect>
      <x>0</x>
      <y>300</y>
      <width>441</width>
      <height>411</height>
     </rect>
    </property>
    <property name="title">
     <string>Terminal Ekranı</string>
    </property>
    <widget class="QTextBrowser" name="logTerminal">
     <property name="geometry">
      <rect>
       <x>0</x>
       <y>20</y>
       <width>421</width>
       <height>331</height>
      </rect>
     </property>
     <property name="layoutDirection">
      <enum>Qt::LayoutDirection::LeftToRight</enum>
     </property>
    </widget>
    <widget class="QPushButton" name="temizleButton">
     <property name="geometry">
      <rect>
       <x>0</x>
       <y>360</y>
       <width>111</width>
       <height>41</height>
      </rect>
     </property>
     <property name="text">
      <string>Temizle</string>
     </property>
    </widget>
   </widget>
   <widget class="QGroupBox" name="baGlantiBilgileriGroupBox">
    <property name="geometry">
     <rect>
      <x>460</x>
      <y>0</y>
      <width>621</width>
      <height>711</height>
     </rect>
    </property>
    <property name="title">
     <string>Bağlantı Bilgileri</string>
    </property>
    <layout class="QVBoxLayout" name="verticalLayout">
     <item>
      <widget class="QLabel" name="statusLabel">
       <property name="text">
        <string>Durum : Bağlı Değil&quot;</string>
       </property>
      </widget>
     </item>
    </layout>
   </widget>
  </widget>
  <widget class="QMenuBar" name="menubar">
   <property name="geometry">
    <rect>
     <x>0</x>
     <y>0</y>
     <width>1096</width>
     <height>22</height>
    </rect>
   </property>
  </widget>
  <widget class="QStatusBar" name="statusbar"/>
 </widget>
 <resources/>
 <connections/>
</ui>
...........................................................

#ifndef DIALWIDGET_H
#define DIALWIDGET_H

#include <QWidget>
#include <QColor>

// Dairesel gösterge bileşeni (widget)
class DialWidget : public QWidget
{
    Q_OBJECT

public:
    explicit DialWidget(QWidget *parent = nullptr);

    // Göstergenin değerlerini ayarlamak için public fonksiyonlar
    void setCurrent(double current);
    void setChannel(int channel);

protected:
    // Bu fonksiyon, widget'ın ekrana çizilmesini sağlar
    void paintEvent(QPaintEvent *event) override;

private:
    double m_current;      // Gösterilecek akım değeri (-20 ila +20)
    int m_channel;         // Gösterilecek kanal (0-6)

    QColor m_needleColor;  // İbrenin rengi
    QColor m_scaleColor;   // Skalanın rengi
    QColor m_textColor;    // Yazıların rengi
    QColor m_fillColor;    // Gösterge dolgu rengi
};

#endif // DIALWIDGET_H

.........................................................................
#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSerialPort>
#include <QVector> // <-- Dizi (vektör) tutmak için eklendi
#include "dialwidget.h" // <-- Gösterge sınıfını dahil ediyoruz

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    // .ui dosyasındaki bileşenlerin 'objectName'lerine göre
    void on_baglanButton_clicked();
    void on_baglantiKesButton_clicked();
    void on_gonderButton_clicked();
    void on_temizleButton_clicked();

    // Serial porttan veri gelince manuel bağladığımız slot
    void on_serial_readyRead();

private:
    Ui::MainWindow *ui;
    QSerialPort *serial;

    // DialWidget *m_dialWidget; // <-- ESKİ (Tek gösterge)
    QVector<DialWidget*> m_dials; // <-- YENİ (7 gösterge için bir liste)

    // Koyu modu uygulamak için yardımcı fonksiyon
    void applyStyleSheet();
};
#endif // MAINWINDOW_H

................................................................................


#include "dialwidget.h"
#include <QPainter>
#include <QPen>
#include <QFont>
#include <QtMath> // qCos ve qSin için

// Constructor (Yapıcı Fonksiyon)
DialWidget::DialWidget(QWidget *parent)
    : QWidget(parent),
    m_current(0.0),
    m_channel(-1) // Başlangıçta kanal seçilmemiş (-1)
{
    // Koyu mod arayüzü için renkleri ayarla
    m_needleColor = QColor("#007bff"); // İbre (Mavi)
    m_scaleColor = QColor("#abb2bf");  // Skala çizgileri (Açık gri)
    m_textColor = QColor("#d4d4d4");   // Yazılar (Beyaz/Gri)
    m_fillColor = QColor("#3c4049");   // Arka plan dolgusu (Koyu Gri)

    // Widget'ın minimum boyutunu ayarla
    setMinimumSize(200, 200);
}

// Değer ayarlandığında widget'ın yeniden çizilmesini tetikle
void DialWidget::setCurrent(double current)
{
    // Gelen değeri -20 ile +20 arasına kısıtla
    if (current > 20.0) m_current = 20.0;
    else if (current < -20.0) m_current = -20.0;
    else m_current = current;

    update(); // 'paintEvent' fonksiyonunu yeniden çağırır
}

// Kanal ayarlandığında widget'ın yeniden çizilmesini tetikle
void DialWidget::setChannel(int channel)
{
    m_channel = channel;
    update(); // 'paintEvent' fonksiyonunu yeniden çağırır
}


// Çizim fonksiyonu
void DialWidget::paintEvent(QPaintEvent *event)
{
    Q_UNUSED(event);

    QPainter painter(this);
    // Çizimin daha pürüzsüz görünmesini sağlar
    painter.setRenderHint(QPainter::Antialiasing);

    // Widget'ın boyutlarını al
    int width = this->width();
    int height = this->height();
    int side = qMin(width, height); // Genişlik ve yükseklikten küçük olanı al

    // Koordinat sistemini widget'ın ortasına taşı
    painter.translate(width / 2.0, height / 2.0);
    // Koordinat sistemini kare alana sığdır
    painter.scale(side / 200.0, side / 200.0); // 200x200'lük bir alana göre ölçekle

    // 1. Gösterge Arka Planını Çiz
    painter.setPen(Qt::NoPen); // Kenarlık olmasın
    painter.setBrush(m_fillColor);
    painter.drawEllipse(-95, -95, 190, 190); // 95 yarıçaplı daire

    // 2. Skala Çizgilerini Çiz
    painter.setPen(m_scaleColor);
    for (int i = 0; i <= 40; ++i) { // 40 adet çizgi (-20'den +20'ye)
        // Her 5 çizgide bir (10'luk adımlar) çizgiyi kalın yap
        if (i % 5 == 0) {
            painter.setPen(QPen(m_scaleColor, 2.5));
        } else {
            painter.setPen(QPen(m_scaleColor, 1.0));
        }

        // Çizgiyi 225 derecelik bir yay üzerine yerleştir (-22.5'tan 202.5'a)
        double angle = -22.5 + (i * (225.0 / 40.0));
        painter.save();
        painter.rotate(angle);
        painter.drawLine(80, 0, 90, 0); // Dairenin dışına doğru çizgi
        painter.restore();
    }

    // 3. Skala Yazılarını Çiz (-20, 0, +20)
    painter.setPen(m_textColor);
    painter.setFont(QFont("Arial", 12, QFont::Bold));

    // -20 (Açı: -22.5 derece)
    painter.drawText(QRectF(-80, 55, 40, 20), Qt::AlignCenter, "-20");
    // 0 (Açı: 90 derece)
    painter.drawText(QRectF(-20, -85, 40, 20), Qt::AlignCenter, "0");
    // +20 (Açı: 202.5 derece)
    painter.drawText(QRectF(40, 55, 40, 20), Qt::AlignCenter, "+20");

    // 4. Akım Değerini Ortaya Yaz
    QString currentText = QString::number(m_current, 'f', 2) + " mA";
    painter.setFont(QFont("Arial", 16, QFont::Bold));
    painter.setPen(m_needleColor); // Akım değeri ibreyle aynı renkte olsun
    painter.drawText(QRectF(-60, -15, 120, 30), Qt::AlignCenter, currentText);

    // 5. Kanal Bilgisini Ortaya Yaz
    QString channelText = (m_channel == -1) ? "Kanal Seçilmedi" : "KANAL " + QString::number(m_channel);
    painter.setFont(QFont("Arial", 10));
    painter.setPen(m_textColor);
    painter.drawText(QRectF(-60, 20, 120, 20), Qt::AlignCenter, channelText);

    // 6. İbreyi Çiz
    // Akım değerini açıya çevir (-20mA = -22.5 derece, +20mA = 202.5 derece)
    double valueAngle = -22.5 + ((m_current + 20.0) / 40.0) * 225.0;

    painter.save();
    painter.rotate(valueAngle);
    painter.setPen(Qt::NoPen);
    painter.setBrush(m_needleColor);

    // İbreyi (üçgen) çiz
    QPolygon needle;
    needle << QPoint(75, 0) << QPoint(-15, -5) << QPoint(-15, 5);
    painter.drawPolygon(needle);
    painter.restore();

    // 7. İbre Merkezini Çiz
    painter.setBrush(m_scaleColor);
    painter.drawEllipse(-5, -5, 10, 10);
}

...................................................

#include "mainwindow.h"
#include "ui_mainwindow.h"  // Tasarım dosyasını dahil et
#include <QSerialPortInfo> // COM portları bulmak için
#include <QDebug>          // Hata ayıklama için
#include <QVBoxLayout>     // Dikey layout için
#include <QGridLayout>     // Izgara (grid) layout için

// Constructor (Yapıcı Fonksiyon)
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow) // 'ui' nesnesini oluştur
{
    // Arayüz tasarımını (mainwindow.ui) yükle
    ui->setupUi(this);

    // 1. Dark Mode Stilini Uygula
    applyStyleSheet();

    // 2. Seri port nesnesini oluştur
    serial = new QSerialPort(this);

    // 3. PC'ye bağlı tüm COM portları bul ve 'comboBox'a ekle
    const auto ports = QSerialPortInfo::availablePorts();
    for (const QSerialPortInfo &port : ports) {
        ui->comboBox->addItem(port.portName());
    }

    // 4. Baud Rate listesini (baudRateComboBox) doldur
    ui->baudRateComboBox->addItem("115200");
    ui->baudRateComboBox->addItem("9600");
    ui->baudRateComboBox->addItem("38400");
    ui->baudRateComboBox->addItem("57600");

    // 5. Başlangıçta "Bağlantı Kes" ve "Gönder" butonlarını pasif yap
    ui->baglantiKesButton->setEnabled(false);
    ui->gonderButton->setEnabled(false); // Bağlantı kurulana kadar gönderme yapamasın

    // 6. Serial porttan veri geldiğinde 'on_serial_readyRead' fonksiyonunu çağır
    connect(serial, &QSerialPort::readyRead, this, &MainWindow::on_serial_readyRead);

    // 7. GÖSTERGEYİ OLUŞTUR VE EKLE (Daha Güvenli Versiyon)

    // 7a. Ana bileşenleri bul ve kontrol et
    QGroupBox *infoBox = ui->baGlantiBilgileriGroupBox;
    QLabel *statusLabel = ui->statusLabel; // .ui dosyasındaki 'statusLabel'

    // Bu iki 'objectName' .ui dosyasında EŞLEŞMEK ZORUNDA
    if (!infoBox) {
        qDebug() << "KRİTİK HATA: .ui dosyasında 'baGlantiBilgileriGroupBox' adında bir QGroupBox bulunamadı!";
        return; // Çökmeyi engelle
    }
    if (!statusLabel) {
        qDebug() << "KRİTİK HATA: .ui dosyasında 'statusLabel' adında bir QLabel bulunamadı!";
        return; // Çökmeyi engelle
    }

    // 7b. Eski layout'u güvenle sil (varsa)
    // ÖNEMLİ: 'statusLabel'i silmemek için onu koru!
    QLayout *existingLayout = infoBox->layout();
    if (existingLayout) {
        QLayoutItem* item;
        while ((item = existingLayout->takeAt(0)) != nullptr) {
            // Eğer silinecek bileşen statusLabel DEĞİLSE güvenle sil
            if (item->widget() && item->widget() != statusLabel) {
                delete item->widget();
            }
            delete item;
        }
        delete existingLayout;
    }

    // 7c. Yeni layout'ları oluştur
    QVBoxLayout *mainInfoLayout = new QVBoxLayout(); // Ana dikey layout
    QGridLayout *gridLayout = new QGridLayout();     // Göstergeler için ızgara

    // 7d. Koruduğumuz statusLabel'i en üste ekle
    statusLabel->setText("Durum : <font color=\"red\">Bağlı Değil</font>");
    mainInfoLayout->addWidget(statusLabel); // Mevcut statusLabel'i yeni layout'a taşı

    // 7e. Göstergeleri oluştur ve ızgaraya ekle
    m_dials.reserve(7); // Vektör için 7 elemanlık yer ayır
    for (int i = 0; i < 7; ++i) {
        DialWidget *dial = new DialWidget(this); // Yeni gösterge oluştur
        dial->setChannel(i);                     // Kanal numarasını ayarla
        dial->setCurrent(0.0);                   // Başlangıç akımı 0.0

        m_dials.append(dial); // Göstergeyi listemize ekle

        // Göstergeyi ızgaraya ekle (örn: 3 sütunlu)
        int row = i / 3; // 0, 0, 0, 1, 1, 1, 2
        int col = i % 3; // 0, 1, 2, 0, 1, 2, 0
        gridLayout->addWidget(dial, row, col);
    }

    // 7f. Izgarayı, ana layout'a ekle
    mainInfoLayout->addLayout(gridLayout);

    // 7g. Ana layout'u grup kutusuna ata
    infoBox->setLayout(mainInfoLayout);
}


// Destructor (Yıkıcı Fonksiyon)
MainWindow::~MainWindow()
{
    // Program kapanırken seri portu düzgünce kapat
    if (serial->isOpen()) {
        serial->close();
    }
    delete serial; // 'serial' nesnesini sil
    // m_dials içindeki widget'lar 'this' (MainWindow) parent'a sahip olduğu
    // için Qt tarafından otomatik silinir, 'delete ui' bunu halleder.
    delete ui;     // 'ui' nesnesini sil
}

// "Bağlantı Kur" butonuna tıklandığında çalışacak kod
void MainWindow::on_baglanButton_clicked()
{
    QString portName = ui->comboBox->currentText();
    if (portName.isEmpty()) {
        ui->logTerminal->append("<font color=\"red\"><b>HATA: Lütfen bir COM portu seçin.</b></font>");
        return;
    }
    serial->setPortName(portName);
    serial->setBaudRate(ui->baudRateComboBox->currentText().toInt());
    serial->setDataBits(QSerialPort::Data8);
    serial->setParity(QSerialPort::NoParity);
    serial->setStopBits(QSerialPort::OneStop);

    if (serial->open(QIODevice::ReadWrite)) {
        // Arayüzü "Bağlandı" durumuna geçir
        ui->baglanButton->setEnabled(false);
        ui->baglantiKesButton->setEnabled(true);
        ui->gonderButton->setEnabled(true);
        ui->comboBox->setEnabled(false);
        ui->baudRateComboBox->setEnabled(false);

        ui->statusLabel->setText("Durum : <font color=\"#28a745\">Bağlantı Kuruldu</font>");
        ui->logTerminal->append("<font color=\"#28a745\"><b>" + portName + " portuna bağlanıldı.</b></font>");

        // Bağlanınca tüm göstergeleri sıfırla
        for (int i = 0; i < m_dials.size(); ++i) {
            m_dials[i]->setChannel(i); // Kanal numarasını göster
            m_dials[i]->setCurrent(0.0); // Akımı 0 yap
        }
    } else {
        qDebug() << "Port açılamadı!";
        ui->statusLabel->setText("Durum : <font color=\"red\">Bağlı Değil</font>");
        ui->logTerminal->append("<font color=\"red\"><b>HATA: " + portName + " portu açılamadı! (Başka bir program kullanıyor olabilir)</b></font>");
    }
}

// "Bağlantı Kes" butonuna tıklandığında
void MainWindow::on_baglantiKesButton_clicked()
{
    if (serial->isOpen()) {
        serial->close();

        // Arayüzü "Bağlantı Kesildi" durumuna geçir
        ui->baglanButton->setEnabled(true);
        ui->baglantiKesButton->setEnabled(false);
        ui->gonderButton->setEnabled(false);
        ui->comboBox->setEnabled(true);
        ui->baudRateComboBox->setEnabled(true);

        ui->statusLabel->setText("Durum : <font color=\"red\">Bağlı Değil</font>");
        ui->logTerminal->append("<font color=\"red\"><b>Bağlantı Kesildi.</b></font>");

        // Bağlantı kesilince tüm göstergeleri sıfırla
        for (DialWidget *dial : m_dials) {
            dial->setCurrent(0.0);
            // Kanal numarasını göstermeye devam etsin
        }
    }
}

// "Temizle" butonuna tıklandığında
void MainWindow::on_temizleButton_clicked()
{
    ui->logTerminal->clear();
}


// "GÖNDER" butonuna tıklandığında
void MainWindow::on_gonderButton_clicked()
{
    if (!serial->isOpen()) {
        ui->logTerminal->append("<font color=\"red\"><b>HATA: Komut gönderilemedi. Port bağlı değil!</b></font>");
        return;
    }

    // 1. Arayüzden değerleri al
    int kanal = ui->spinBox->value(); // Kanal (0-6)
    double akim_mA = ui->doubleSpinBox->value(); // Akım (-20.0 ila +20.0)

    // 2. Akım Değerini İstenen Formata Çevir (10.5mA -> 10500)
    int komutDegeri = (int)(akim_mA * 1000.0);

    // 3. STM32'ye göndermek için komut metnini oluştur
    // Format: "SET:Kanal:Değer\n"
    QString command = QString("SET:%1:%2\n").arg(kanal).arg(komutDegeri);

    // 4. Komutu seri porttan gönder
    serial->write(command.toUtf8());

    // 5. Gönderilen komutu terminale yazdır
    ui->logTerminal->append(QString("TX: %1").arg(command.trimmed()));

    // 6. YENİ ADIM: SADECE İLGİLİ GÖSTERGEYİ GÜNCELLE
    if (kanal >= 0 && kanal < m_dials.size()) {
        m_dials[kanal]->setChannel(kanal);
        m_dials[kanal]->setCurrent(akim_mA);
    }
}

// STM32'den seri port aracılığıyla bir veri geldiğinde bu fonksiyon çalışır
void MainWindow::on_serial_readyRead()
{
    while (serial->canReadLine()) {
        QByteArray data = serial->readLine();
        QString receivedText = QString::fromUtf8(data).trimmed();

        // Gelen veriyi (mavi-yeşil renkte) terminale yazdır
        ui->logTerminal->append(QString("<font color=\"#34c2eb\">RX: %1</font>")
                                    .arg(receivedText));

        // Gelişmiş Adım (İsteğe bağlı):
        // STM32'den gelen cevabı (RX) parse edip göstergeyi de güncelleyebilirsiniz.
        // Örn: STM32 size "KANAL:0,AKIM:10.5" diye cevap verirse:
        /*
        if (receivedText.startsWith("KANAL:")) {
            QStringList parts = receivedText.split(QRegularExpression("[,:]"));
            if (parts.size() == 4) { // ["KANAL", "0", "AKIM", "10.5"]
                int ch = parts[1].toInt();
                double cur = parts[3].toDouble();
                if (ch >= 0 && ch < m_dials.size()) {
                    m_dials[ch]->setCurrent(cur);
                }
            }
        }
        */
    }
}

// Dark Mode stil kodunu (QSS) uygular
void MainWindow::applyStyleSheet()
{
    QString qss = R"(
        /* Ana Pencere ve Arkaplan */
        QMainWindow, QWidget {
            background-color: #282c34;
        }

        /* Grup Kutuları (Bağlantı Ayarları, Terminal vb.) */
        QGroupBox {
            background-color: #3c4049;
            border: 1px solid #545862;
            border-radius: 8px;
            margin-top: 10px; /* Başlık için yer aç */
            font-weight: bold;
        }

        /* Grup Kutusu Başlıkları */
        QGroupBox::title {
            subcontrol-origin: margin;
            subcontrol-position: top center;
            padding: 0 10px;
            background-color: #3c4049;
            color: #abb2bf;
        }

        /* Tüm Yazılar (Label) */
        QLabel {
            color: #abb2bf;
            font-weight: bold;
            background-color: transparent; /* Grup kutusunun içindeki label'lar için */
        }

        /* Bağlantı Bilgileri - Durum Yazısı (Özelleştirme) */
        #statusLabel {
            color: #abb2bf;
            font-size: 14px;
        }

        /* ComboBox (Port Listesi) ve SpinBox (Sayı Kutuları) */
        QComboBox, QSpinBox, QDoubleSpinBox {
            background-color: #21252b;
            color: #d4d4d4;
            border: 1px solid #545862;
            border-radius: 4px;
            padding: 5px;
        }

        QComboBox::drop-down, QSpinBox::up-button, QSpinBox::down-button, QDoubleSpinBox::up-button, QDoubleSpinBox::down-button {
            border: 1px solid #545862;
            background-color: #282c34;
            color: #d4d4d4;
        }

        QComboBox QAbstractItemView {
            background-color: #21252b;
            color: #d4d4d4;
            selection-background-color: #007bff;
        }

        /* Terminal Ekranı */
        QTextBrowser {
            background-color: #1e1e1e;
            color: #d4d4d4;
            border: 1px solid #545862;
            border-radius: 4px;
        }

        /* Tüm Butonlar (Varsayılan Stil) */
        QPushButton {
            color: white;
            background-color: #545862;
            border: none;
            border-radius: 5px;
            padding: 10px;
            font-weight: bold;
        }

        QPushButton:hover {
            background-color: #6a6e78;
        }

        QPushButton:pressed {
            background-color: #4a4e58;
        }

        /* Pasif (Disabled) Buton Stili */
        QPushButton:disabled {
            background-color: #4a4e58;
            color: #888;
        }

        /* --- BUTONLARI objectName'e GÖRE ÖZELLEŞTİRME --- */

        /* Bağlantı Kur Butonu (Yeşil) */
        #baglanButton {
            background-color: #28a745; /* Yeşil */
        }
        #baglanButton:hover {
            background-color: #218838;
        }
        #baglanButton:pressed {
            background-color: #1e7e34;
        }

        /* Bağlantı Kes Butonu (Kırmızı) */
        #baglantiKesButton {
            background-color: #dc3545; /* Kırmızı */
        }
        #baglantiKesButton:hover {
            background-color: #c82333;
        }
        #baglantiKesButton:pressed {
            background-color: #bd2130;
        }

        /* GÖNDER Butonu (Mavi) */
        #gonderButton {
            background-color: #007bff; /* Mavi */
        }
        #gonderButton:hover {
            background-color: #0069d9;
        }
        #gonderButton:pressed {
            background-color: #0062cc;
        }

        /* Temizle Butonu (Sarı/Turuncu) */
        #temizleButton {
            background-color: #ffc107; /* Sarı */
            color: #21252b; /* Koyu yazı */
        }
        #temizleButton:hover {
            background-color: #e0a800;
        }
        #temizleButton:pressed {
            background-color: #d39e00;
        }
    )";

    // Stili ana pencereye uygula
    this->setStyleSheet(qss);
}

