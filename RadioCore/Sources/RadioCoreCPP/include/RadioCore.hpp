#pragma once
#include <cstdint>

namespace rc {

struct Status {
    enum class Kind { Seek, Tune, Rds, Raw } kind;
    bool success{false};
    double freqMHz{0.0};
    uint8_t strength{0};
    uint8_t error{0};
    uint8_t rds[8]{0};
};

enum class ChannelSpacing : uint16_t { khz200 = 0, khz100 = 1, khz50 = 2 };

class BesFM {
public:
    BesFM();
    ~BesFM();

    bool isOpen() const;

    void setPower(bool on);
    bool getPower() const;

    void setRecording(bool on);
    bool getRecording() const;

    void setChannelSpacing(ChannelSpacing s);
    uint8_t getChannelSpacing() const;

    void setMute(bool on);
    bool getMute() const;

    void setVolume(uint16_t vol);
    uint8_t getVolume() const;

    void setChannel(double mhz);
    double getChannel() const;

    uint8_t getRssi() const;

    Status getStatus() const;

private:
    void* dev_{nullptr};
};

}


