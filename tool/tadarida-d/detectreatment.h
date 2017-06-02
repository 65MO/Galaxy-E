#ifndef DETECTREATMENT_H
#define DETECTREATMENT_H

#include <float.h>
#include <iostream>
#include <QDate>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QtCore/qmath.h>
#include <QTextStream>
#include <QProcess>

#include <QVector>
#include "sndfile.h"
#include "fftw3.h"

#include <QPoint>

#define	FFT_HEIGHT_MAX 4096
#define	FFT_HEIGHT_HALF_MAX 2048
#define FREQ_MAX 250 // KHz
//� #define MAXLARCRI 10000
#define MAXLARCRI 10000
#define MAXHEIGHT 500
#define PI	3.14159265358979

//� #define SONOGRAM_WIDTH_MAX 65535
#define SONOGRAM_WIDTH_MAX 60008
#define  LD8 (SONOGRAM_WIDTH_MAX+15)/8

#define SONOGRAM_WIDTH_MIN 64

//� #define MAXCRI 2000
#define MAXCRI 1500
#define NCRETES 5
#define EMIN -100

#define WITHNEWPARAM true

class Detec;
class Recherche;

enum NUMTAB {SH,CM,CS,CN,CO,CO2,NBTAB};
enum NUMPAR {StTime,Dur,PrevSt,Fmax,Fmin,BW,FPk,FPkD,TPk,Slope,ISlope,HCF,FIF,THCF,UpSl,LoSl,StF,
     EnF,StSl,EnSl,FPSl,FISl,CeF,B5dBBF,B5dBAF,B5dBBW,B5dBDur,LCF,FreqMP,
     PosMP,FreqPkS,FreqPkM,PosPkS,PosPkM,FreqPkS2,FreqPkM2,PrevMP1,
     PrevMP2,NextMP1,NextMP2,Amp1,Amp2,Amp3,Amp4,NoisePrev,NoiseNext,NoiseDown,NoiseUp,
     CVAmp,Hup_RFMP,Hup_PosMP,Hup_PosSt,Hup_PosEn,Hup_AmpDif,Hup_RSlope,Hlo_RFMP,Hlo_PosMP,
     Hlo_PosSt,Hlo_PosEn,Hlo_AmpDif,Hlo_RSlope,Ramp_2_1,Ramp_3_1,Ramp_3_2,Ramp_1_2,Ramp_4_3,
     Ramp_2_3,RAN_2_1,RAN_3_1,RAN_3_2,RAN_1_2,RAN_4_3,RAN_2_3,HetX,HetY,Dbl8,Stab,Rythm1,Rythm2,Rythm3,
     HeiET,HeiEM,HeiRT,HeiRM,HeiETT,HeiEMT,HeiRTT,HeiRMT,MedInt,Int25,Int75,RInt1,IntDev,SmIntDev,LgIntDev,
     VarInt,VarSmInt,VarLgInt,RIntDev1,EnStabSm,EnStabLg,HetXr,HetYr,HetCMC,HetCMD,HetCTC,HetCTD,
     HetCMnP,HetCMfP,HetCTnP,HetCTfP,
     HetPicsMAD,HetPicsMALD,HetPicsMABD,HetPicsMRBLD,HetPicsTAD,HetPicsTALD,HetPicsTABD,HetPicsTRBLD,
     VDPicsM,VLDPicsM,VBDPicsM,VDPPicsM,VLDPPicsM,VBDPPicsM,
     VDPicsT,VLDPicsT,VBDPicsT,VDPPicsT,VLDPPicsT,VBDPPicsT,
     HetYr2,SDC,SDCR,SDCRY,SDCRXY,
     SDCL,SDCLR,SDCLRY,SDCLRXY,SDCLRXY2,
     SDCLOP,SDCLROP,SDCLRYOP,SDCLRXYOP,
     SDCLWB,SDCLRWB,SDCLRYWB,SDCLRXYWB,
     SDCLOPWB,SDCLROPWB,SDCLRYOPWB,SDCLRXYOPWB,
     SDCL_DNP,SDCLR_DNP,SDCLRY_DNP,SDCLRXY_DNP,SDCLRXY2_DNP,
     ELBPOS,ELBSB,ELB2POS,ELB2SB,
     RAF,RAE,RAFE,RAFP,RAFP2,RAFP3,
     SBMP,SAMP,SBAR,
     RAHP2,RAHP4,RAHP8,RAHP16,RAHE2,RAHE4,RAHE8,RAHE16,
     NBPAR};

enum NUMERROR {FNREC,MCNT,DTP,DTG,TNT,NTERRORS};


class ParamToSave
{
public:
    ParamToSave(int,int,QString);
    ParamToSave(int,int,QString,int);
    ParamToSave(int,int,QString,int,int);
    ParamToSave();
    ~ParamToSave();

    int NumTableau;
    int NumPar;
    QString ColumnTitle;
    QString InfoLabel;
    int NeedVer;
    int LimVer;
};


class DetecTreatment
{
public:
    DetecTreatment(Detec *);
    DetecTreatment(Recherche *);
    ~DetecTreatment();
    bool CallTreatmentsForOneFile(QString& wavFile,QString &pathFile);
    void EndDetecTreatment();
    void InitializeDetecTreatment();
    void saveDatFile(QString wavFile);
    void SetDirParameters(QString,QString,bool,QString,QString);
    void SetGlobalParameters(int,int,int,int,int,int,bool,int,int,int,int,int,int,int,int,int,int);
    void sortFloatIndArray(float *,int,int *);

    QVector< ParamToSave >       _vectPar;
    int			                 _sonogramWidth;
    int			                 _fftHeightHalf;
    double			             _energyMax;
    double		                 _energyMin;
    int                           _limY;
    qint16 **                 _sonogramArray;
    float                        _energyShapeThreshold;
    float                        _energyStopThreshold;
    char**                       _pointFlagsArray;
    int NError;
    int TabErrors[NTERRORS];
    bool                         *_flagGoodColInitial;
    bool                         *_flagGoodCol;
    bool _withSilence;


private:
    // methods
    //void calculateMedianNoise();
    void clearVars();
    bool computeFFT(QString &);
    void correctNoise();
    void detectsParameter2();
    void initVectorParams();
    bool openWavFile(QString &);
    void saveParameters(const QString&);
    void saveCompressedParameters(const QString&);
    //void expandParameters(const QString&);
    void shapesDetects();
    void sortWaves();
    void sortFloatArray(float *,int);
    void sortIntArrays(int *,int,int *);
    void aff(QString,qint64,int);
    bool determineLeftOrRight(QString &);

    // attributes
    Detec                        *_detec;
    float                        *_averagePerX;
    QDir                         _baseDayDir;
    float                        _callEnergyMax ;
    int                          _callEnergyMaxIndex;
    QVector< QVector<QPoint> >   _callsArray;
    QVector<QPoint>              _callMasterRidge;
    QVector< QVector<QPoint> >   _callMasterRidgeArray;
    QFile                        _callMatrixFile;
    QString                      _callMatrixName;
    QDataStream                  _callMatrixStream;
    QVector<QPoint>              _callNorthRidge;
    QVector< QVector<QPoint> >   _callNorthRidgeArray;
    QVector<QPoint>              _callSecondWestRidge;
    QVector< QVector<QPoint> >   _callSecondWestRidgeArray;
    QVector<QPoint>              _callSouthRidge;
    QVector< QVector<QPoint> >   _callSouthArray;
    QVector<QPoint>              _callWestRidge;
    QVector< QVector<QPoint> >   _callWestRidgeArray;
    int                          _callsNumber;
    char *                       _charParamsArray;
    char *                       _charTabX;
    char *                       _charTabYX;
    char *                       _charYEmaxPerX;
    float                        *_coeff;
    //fftwf_complex*	             _complexInput;
    QFile                        _compressedParametersFile;
    QDataStream                  _compressedParametersStream;
    int                          _paramVersion;
    int                          _compressedVersion;
    float*			             _data;
    QString                      _datPath;
    int                          _detectionThreshold;
    float                        **_dpm;
    int                          **_dypm;
    float                        *_eMaxPerX;
    float                        *_energyMoyCol;
    QFile                        _expandParametersFile;
    QDataStream                  _expandParametersStream;
    int			                 _fftHeight;
    //fftwf_complex*	             _fftRes;
    float                        _freqCallMin;
    int                          _freqMin;
    int                          **_harmonic;
    bool                         _imageData;
    QString                      _imagePath;
    int                          *_inflexion1;
    int                          *_inflexion3;
    int				             _iOverlapMoving;
    float                        _khzPerY;
    bool                         _littleParams;
    int                          *_lowSlope;
    QVector< QPoint >            _masterPoints;
    int                          _maxCallWidth;
    int                          _maxCallHeight;
    int                          _maxY;
    //int			                 _medianNoise;
    int                          _minY;
    float                        _msPerX;
    int	                         _nbo;
    int                          _numberCallParameters;
    int                          *_numberPixelsPerX;
    int                          *_numberPixelsPerY;
    float***                     _paramsArray;
    float**                      _simpleParamsArray;
    float**                      _valuesToCompressArray;

    int                          _patience;
    //fftwf_plan		         _plan;
    fftwf_plan		             *_pPlan;
    int                          _iH;
    fftwf_complex*	             _complexInput;
    fftwf_complex*	             _fftRes;
    QString                      ResultSuffix;
    QString                      ResultCompressedSuffix;
    bool                         _saveTitleLine;
    float                        *_slope;
    //� float **                 _sonogramArray;
    SNDFILE*		             _soundFile;
    SF_INFO			             _soundFileInfo;
    int                          _stopThreshold;
    float                        **_tabX;
    float                        *_tabY;
    float                        **_tabYX;
    int	                         _timeExpansion;
    int	                         _timeExpansionLeft;
    int	                         _timeExpansionRight;
    bool                         _treating;
    QFile                        _txtFile;
    QString                      _txtPath;
    QFile                        txtFile;
    QString                      _txtFilePath2;
    uint                         _tvaleur[2000];
    QVector< QPoint >            _vectorCallPoints;
    QVector < int >              _vectorXMin;
    QVector < int >              _vectorXMax;
    QString                     _wavFile;
    QStringList                  _wavFileList;
    QString                      _wavPath;
    int                          _xMax;
    int                          *_xMaxPerY;
    int                          _xMin;
    //� int                    *_xMinPerY;
    quint16                   *_xMinPerY;
    //� int                          *_xSecondWestRidgePerY;
    quint16                  *_xSecondWestRidgePerY;
    //� int                      **_yEmaxPerX;
    quint16                   **_yEmaxPerX;
    float                       *_yEbarPerX;
    float                       *_totYEPerX;
    int                          _yMax;
    //� int                          *_yMaxPerX;
    quint16                          *_yMaxPerX;
    int                          _yMin;
    //� int                     *_yMinPerX;
    quint16                   *_yMinPerX;
    int                          **_ypm;
    char                     *_charSonogramArray;
    char                     *_charPointFlagsArray;
    // ajout� pour nouveaux param�tres
    bool _useValflag;
    int _jumpThreshold;
    int _widthBigControl;
    int _widthLittleControl;
    int _highThresholdJB;
    int _lowThresholdJB;
    int _lowThresholdC;
    int _highThresholdC;
    int _qR;
    int _qN;
    bool _fileProblem;
    //bool _withNewParams;
    int *sortMp;
    int *invMp;
    int *xMp;
    bool _firstFile;
    //
};

#endif // DETECTREATMENT_H