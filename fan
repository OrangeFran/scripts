#! /usr/bin/env nix-shell 
#! nix-shell -i python3 -p python3Packages.toml python3Packages.colorama

import os, sys, time
import argparse
import toml

from colorama import init, Fore

init()

presets = {
    # name: (fan1, fan2),
    "min":  (1250, 1350),
    "mid":  (2500, 2500),
    "high": (4000, 4000),
    "max":  (6336, 6864),
}

# Add or remove to your liking
fans = [ "F0", "F1" ]

def smc(flags: str) -> str:
    """
    Wrapper around the smc binary.
    How: `smc("-f ... -k ...")`
    """
    cmd = f"/usr/local/bin/smc {flags}"
    return os.popen(cmd).read()

class Mode():
    """
    There are two modes.
    Auto: the os decides how to use the fans.
    Custom: you decide how to use the fans.
    """
    AUTO = 0
    CUSTOM = 1

def set_mode(mode: int):
    """
    Change the mode for all fans.
    Choose between the modes from the Mode class.
    """
    for fan in fans:
        if mode == Mode.AUTO:
            smc("-k {}Md -w 00".format(fan))
        elif mode == Mode.CUSTOM:
            smc("-k {}Md -w 01".format(fan))
        else:
            print("No such mode: {}".format(mode))
            sys.exit(1)

def apply(preset):
    """
    Apply a preset.
    """
    speed = presets[preset]
    for i, fan in enumerate(fans):
        smc("-k {}Tg -p {}".format(fan, speed[i]))

def status():
    """
    Output the current temperatures and the fan speeds.
    """
    rpm = int(smc("-k F0Ac -r").split(" ")[7])
    temp = int(float(smc("-k TC0P -r").split(" ")[6]))

    # Color the output
    if temp > 60:
        temp = "{}{}{}".format(Fore.RED, temp, Fore.RESET)
    if rpm > 3500:
        rpm = "{}{}{}".format(Fore.GREEN, rpm, Fore.RESET)

    return "{}°C / {} rpm".format(temp, rpm)


# Create the argument parser
parser = argparse.ArgumentParser()
parser.add_argument(
    "-c", "--config",
    help="Uses an alternate config file",
)

# One of these has to be used
action_group = parser.add_mutually_exclusive_group()
action_group.add_argument(
    "-a", "--apply", 
    help="Applies a preset to your fans",
    choices=presets.keys(),
)
action_group.add_argument(
    "-t", "--auto",
    help="Switches to automatic mode",
    action="store_true"
)
action_group.add_argument(
    "-l", "--list",
    help="Lists all available presets",
    action="store_true"
)
action_group.add_argument(
    "-s", "--status",
    help="Displays the current temperatures and fan speeds",
    action="store_true"
)
action_group.add_argument(
    "-i", "--interactive",
    help="Like `--status` but with updates every two seconds",
    action="store_true"
)

args = parser.parse_args()

if args.auto:
    set_mode(Mode.AUTO)

elif args.list:
    print("\n".join(presets.keys()))

elif args.apply:
    set_mode(Mode.CUSTOM)
    apply(args.apply)

elif args.status:
    print(status())

elif args.interactive:
    # Hide the cursor (is there a better way?)
    import curses
    curses.initscr()
    curses.curs_set(0)
    try:
        while True:
            # Overrides the line
            print(status(), end="\r")
            time.sleep(2)
    except KeyboardInterrupt:
        print("Stopping ... ")
        curses.curs_set(1)
        curses.endwin()

else:
    print("Use `-h` or `--help` for more information")
    exit(1)

# export PATH=/usr/local/bin:$PATH
# 
# declare -A presets
# presets[min]="1250:1350"
# presets[mid]="2500:2500"
# presets[high]="4000:4000"
# presets[max]="6336:6864"
# 
# barrefresh() {
#     echo "Refreshing widget ..."
#     sleep 5
#     open -g "bitbar://refreshPlugin?name=cpu*.sh"
# }
# 
# apply() {
#     custom
#     speeds=${presets[$1]}
#     echo "Applying custom preset $1 ($speeds) ..."
#     arr=($(echo $speeds | tr ':' '\n'))
#     smc -k F0Tg -p ${arr[1]}
#     smc -k F1Tg -p ${arr[2]}
#     
#     barrefresh
# }
# 
# custom() {
#     smc -k F0Md -w 01
#     smc -k F1Md -w 01
# }
# 
# auto() {
#     smc -k F0Md -w 00
#     smc -k F1Md -w 00
# 
#     barrefresh
# }
# 
# list() {
#     smc -f
# }
# 
# temp() {
#     echo $(smc -k TC0P -r | awk '{ print int($3) }')
# }
# 
# rpm() {
#     echo $(smc -k F0Ac -r | awk '{ print $4 }')
# }
# 
# status() {
#     NC='\033[0m'
#     RED='\033[0;31m'
#     t=$(temp)
#     if [[ $t > 60 ]]; then
#         printf "${RED}$(temp)°C${NC} / $(rpm) rpm"
#     else 
#         printf "$(temp)°C / $(rpm) rpm"
#     fi
# }
# 
# case "$1" in
#     "auto") auto;;
#     "l" | "list") list;;
#     "min" | "mid" | "high" | "max") apply "$1";;
#     "i" | "interactive")
#         while : ; do
#             status
#             echo -en "\r"
#             sleep 1
#         done
#         ;;
#     "t" | "temp") temp;;
#     "r" | "rpm") rpm;;
#     "") status;;
#     *) echo -e "No such command: "$1"\nUsage: fan <min/mid/high/max>\n       fan <auto> | <list> | <temp> | <rpm> | <status>";;
# esac
