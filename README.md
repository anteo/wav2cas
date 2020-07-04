# wav2cas

This utility can be used to convert audio records (in WAV format) saved with TRS-80 (Model I/III) to a CAS file for use by TRS-80 emulators.

It was created as a result of an attempt to understand what format of data stored on some old tapes found on my bookshelf :-)

It's HIGHLY experimental, so if you got here, please use other well-known utility for conversion: http://knut.one/wav2cas.htm

If you can't restore records in mentioned utility (as I did) so you can try this one. It contains some options which allow you to restore data even without lead tone.

It accepts WAV files with any sample rate (11025 / 22050 / 44100) and format (float / 8-bit / 16-bit / stereo / mono), uses auto-detection mechanism to get clock frequency which depends on baud rate (model I level2 500baud, level1 250baud or model III highspeed 1500 baud).

## Installation

You should have Ruby >= 2.3.0 prior installed. Then type command to install wav2cas:

```ruby
gem install wav2cas
```

## Usage

```
Usage: wav2cas [options] <input.wav>
    -d, --double                     Double density
    -o, --output FILENAME            Output file
    -s, --skip N                     Skip N seconds from the beginning of file
    -l, --no-lead-tone               Audio doesn't start from lead tone (use to recover corrupted records)
    -a, --auto-align                 Try to auto align (could fix some records)
    -t, --threshold THRESHOLD        Peak detection threshold (5-15). Default: 10
```

## Examples

All samples except of `sample4` and `sample6` are processed successfully without additional options.

```
wav2cas samples/graph_it.wav
wav2cas samples/sample1.wav
wav2cas samples/sample2.wav
wav2cas samples/sample3.wav
wav2cas -a -t 20 samples/sample4.wav
wav2cas samples/sample5.wav
wav2cas -a -t 20 samples/sample6.wav
```

## Contributing

If you have audio records which can not be recognized with this utility, send it to <anton.argirov@gmail.com>, I will try to improve.

Bug reports and pull requests are welcome on GitHub at https://github.com/anteo/wav2cas.

