defmodule Site.Components.Icons.SvgIcon do
  defstruct [icon: :bus, class: "", show_tooltip?: true]

  @type t :: %__MODULE__{icon: icon_arg, class: String.t, show_tooltip?: boolean}
  @type icon_arg :: atom | String.t | Routes.Route.t | 0..4

  @mode_icons [:bus, :ferry, :subway, :commuter_rail, :mattapan_trolley, :t_logo,
               :green_line, :orange_line, :blue_line, :red_line]

  @icons [
    {:bus,
        "M11 15H5c-.005.553-.446 1-.999 1H2.999A.999.999 0 0 1 2 15c-.553-.004-1-.45-1-1.002v-.496-12.5C1 .449 1.45 0 2.007 0h11.986C14.55 0 15 .445 15 1.002v12.996c0 .55-.446.998-1 1.002-.005.553-.446 1-.999 1h-1.002A.999.999 0 0 1 11 15zM9 4v6h5V4H9zM2 4v6h5V4H2zm2-3v2h8V1H4zm8 11c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-3 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-4 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1zm-3 0c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1z"},

    {:commuter_rail,
        "M2 5.34V3c0-.552.432-1.144.95-1.317L7.05.317c.524-.175 1.382-.173 1.9 0l4.1 1.366c.524.175.95.76.95 1.317v2.34l1 .285v5.565c0 .55-.45.996-1.007.996H2.007A1.005 1.005 0 0 1 1 11.19V5.625l1-.286zM13 10a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM3 10a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm0-7v2l4-1V2L3 3zm6-1v2l4 1V3L9 2zM2 13h12v.5c0 .276-.229.5-.5.5h-11a.505.505 0 0 1-.5-.5V13zm3 1h2l-2 2H3l2-2zm4 0h2l2 2h-2l-2-2z"},

    {:subway,
        "M4.5 15L4 16H3l.5-1h-.498A1.001 1.001 0 0 1 2 13.998v-.496V3.007c0-.556.386-1.244.863-1.512C2.863 1.495 5 0 8 0c3 0 5.137 1.495 5.137 1.495.477.279.863.956.863 1.512v10.991C14 14.55 13.544 15 12.998 15H12.5l.5 1h-1l-.5-1h-7zM5 3c0 .556.444 1 .99 1h4.02A1 1 0 0 0 11 3c0-.556-.444-1-.99-1H5.99A1 1 0 0 0 5 3zM3.5 4a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1zm9 0a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1zM12 14a1 1 0 1 0 0-2 1 1 0 0 0 0 2zm-8 0a1 1 0 1 0 0-2 1 1 0 0 0 0 2zM3 5.99v4.02c0 .539.446.99.995.99h8.01a1 1 0 0 0 .995-.99V5.99c0-.539-.446-.99-.995-.99h-8.01A1 1 0 0 0 3 5.99z"},

    {:ferry,
        "M2 7V3l6-3 6 3v4l2 1s-3.98 4-4 7c-.408 0-1-1-2-1s-1 1-2 1-1-1-2-1-1.488 1-2 1c.044-3-4-7-4-7l2-1zm1-3v2l4-2V2L3 4zm6-2v2l4 2V4L9 2z"},

    {:half_bus,
        "M0.5,0 l7,0 l0,2.58 l-6.75,0 a24,24 0 0 1 0.75,-2.58 m6.5,0 l0.5,0 l2,2.08 l0,0.5 l-2.5,0 m-7.3,0.5 l19,0
        l0,2 l-1,0 a10,10 0 0 1 1,3 l0.75,5 l0.5,0.1 l0.1,2 l-7,0 a3,3 0 0 0 0.1,-1 a1,1 0 0 0 -5,0 a3,3 0 0 0 0.1,1
        l-8,0 a24,24 0 0 1 -1,-5.1 l2,0 a1,1 0 0 0 1,-1 l0,-3 a1,1 0 0 0 -1,-1 l-1.95,0 a24,24 0 0 1 0.4,-2 m5,2 l6,0
        a1,1 0 0 1 1,1 l0,3 a1,1 0 0 1 -1,1 l-6,0 a1,1 0 0 1 -1,-1 l0,-3 a1,1 0 0 1 1,-1 m10,0 l1,0 a1,1 0 0 1 1,1 l0,3
        a1,1 0 0 1 -1,1 l-1,0 a1,1 0 0 1 -1,-1 l0,-3 a1,1 0 0 1 1,-1 m-4,7.15 a1,1 0 0 0 0,4 a1,1 0 0 0 0,-4 m0,1.5
        a0.5,0.5 0 0 1 0,1 a0.5,0.5 0 0 1 0,-1"},

    {:t_logo,
        "M10 6h6V2H0v4h6v10h4V6z"},

    {:alert,
        "m10.981,1.436c0.818,-1.436 2.15,-1.425 2.962,0l10.166,17.865c0.818,1.437 0.142,2.602 -1.52,2.602l-20.259,0c-1.657,0 -2.33,-1.176 -1.52,-2.602l10.172,-17.865l-0.001,0zm-0.359,6.92l3,0l0,6l-3,0l0,-6zm0,7.53l3,0l0,3l-3,0l0,-3z"},

    {:access,
        "M17 22.4c-1.5 3-4.6 5-8 5-5 0-9-4-9-9 0-3.5 2-6.7 5.3-8.2l.2 2.7c-2 1-3 3.2-3 5.4C2.5 22 5.5 25 9 25
        c3.3 0 6-2.6 6.5-5.8l1.6 3.2zM8 5c1.3-.2 2.2-1.3 2.2-2.6S9.2 0 7.8 0C6.5 0 5.4 1 5.4 2.4c0 .5 0 1 .3 1.2L6.5 16
        h9l3.7 8.5 4.8-2-.7-1.7-2.7 1-3.6-8.2H8.7V12h6V10H8.2l-.3-5z"},

    {:search,
        "m 57.396003,7.8603731 c 18.708661,0 34.015747,15.2716529 34.015747,33.9803139 0,18.708661 -15.307086,34.015748 -34.015747,34.015748 -7.192914,0 -13.854331,-2.30315 -19.346457,-6.129921 l -18.389763,18.35433 c -2.338583,2.374016 -6.165354,2.374016 -8.503937,0 -2.338582,-2.338583 -2.338582,-6.129921 0,-8.468504 L 29.54561,61.222577 c -3.862205,-5.527559 -6.129922,-12.188976 -6.129922,-19.38189 0,-18.708661 15.307087,-33.9803139 33.980315,-33.9803139 z m 0,11.9763779 c -12.188976,0 -21.968504,9.779527 -21.968504,22.003936 0,12.22441 9.779528,22.003937 21.968504,22.003937 12.224409,0 22.003936,-9.779527 22.003936,-22.003937 0,-12.224409 -9.779527,-22.003936 -22.003936,-22.003936 z"},

    {:map,
        "M1,4 l8,-3 l8,3 l8,-3 l0,20 l-8,3 l-8,-3 l-8,3 Z M9,2 l0,19 M17,4 l0,19"},

    {:globe,
        "M5,5 a10,10 0 0 1 20,20 a10,10 0 0 1 -20,-20 m-1,1 l22,0 m3,8 l-28,0 m2,8 l24.5,0 m-12.5,7 l0,-28 m0,0
        a12,15 0 0 0 0,28 a12,15 0 0 0 0,-28"},

    {:phone,
        "M1 .4c-1.8 8 4.2 21 14.7 22l1.7-5s0-.4-.3-.6l-4.4-2.6-2.7 1.3c-1.5-1.2-4.4-4.6-5-7 1-.8 2.3-2.2 2.3-2.2
        s-.8-5-1-5.4c0-.5-.2-.6-.6-.6H1z"},

    {:suitcase,
        "M7.0893.1035c-.2945.0277-.519.2756-.518.5714v2.857H0v5.4286h10.2857V7.532h3.4286v1.4286H24V3.532h-6.5714V.675
        c0-.3157-.256-.5715-.5715-.5715H7.143c-.018-.001-.036-.001-.0537 0zm.625 1.1428h8.5714V3.532H7.7143V1.2464z
        M0 10.1035v8.857h24v-8.857H13.7143v1.4286h-3.4286v-1.4285H0z"},

    {:tools,
        "M12.54 9.3c.25-.26.45-.3.76.02l.25.23
        c.12-.1.2-.17.28-.26 1.72-1.72 3.4-3.44 5.1-5.16.23-.22.42-.5.57-.8 1.12-2.02.67-1.54 2.56-2.66l.62-.34
        c.08-.03.17-.1.25-.1.45-.04.5.1.76.4.2.26.16.52 0 .8-.37.6-.68 1.18-1.05
        1.77-.14.24-.34.43-.54.55-.5.3-1.06.6-1.6.9-.16.08-.3.2-.44.3-1.8 1.73-3.55 3.5-5.3 5.25-.2.2-.22.33 0
        .53.26.25.26.5 0 .76l-2.22-2.2zm-1.04 5.88
        c-.57.28-1.47 1.04-1.97 1.46-.88.77-1.64 1.67-2.1 2.74-.16.36-.2.78-.33 1.2-.05.15-.1.32-.2.4-.75.8-1.54
        1.58-2.33 2.37-.73.7-1.86.7-2.6 0-.47-.45-.78-.73-1.23-1.2-.7-.72-.73-1.82-.06-2.55.8-.84 1.64-1.66
        2.45-2.48.06-.05.17-.1.26-.14 1.1-.14 2.07-.67 2.92-1.4.9-.77 2.05-2 2.53-3.08l2.65 2.68z m10.56 8.8c-.48
        0-.85-.27-1.18-.58
        l-6.45-6.47c-2.06-2.06-4.1-4.1-6.14-6.1-1.08-1.1-2.35-1.93-3.76-2.5-.42-.16-.82-.02-1.2.12-.12.03-.3.06-.38 0
        C1.44 7.45.46 6.08 0 4.3c-.02-.1.04-.33.12-.38.08-.06.28 0 .4.05 1.15.68 2.3 1.35 3.5 2
        .5.28.5.28.8-.22.34-.6.68-1.16 1-1.75.2-.37.13-.56-.24-.8-1.15-.66-2.3-1.34-3.46-2.04-.1-.06-.28-.26-.25-.3.05-.16.2-.3.3-.32
        C3.4.14 4.66-.08 5.96.04c2.2.2 3.77 2.16 3.52 4.35-.2 1.63.3 2.95 1.46 4.08L23.43 21 c.57.57.7
        1.28.4 1.95-.34.68-1 1.1-1.77 1.04zm.84-1.06c.3-.3.28-.92-.03-1.26-.33-.37-.98-.4-1.3-.1-.33.35-.3.9
        7.04 1.3.35.37 1 .4 1.3.06z"},
    {:the_ride,
     "M9.987 7v1.547H6.942v8.575H5.06V8.547H2V7h7.987zm9.737
     10.122h-1.897v-4.424H13.08v4.424h-1.896V7h1.897v4.354h4.747V7h1.897v10.122zM28.152
     7v1.498h-4.487v2.807H27.2v1.45h-3.535v2.862h4.487v1.505h-6.384V7h6.384zM4.8 25.167v3.955H2.917V19h3.087c.69
     0 1.282.07 1.775.213.49.143.894.342 1.21.6.315.256.545.562.692.92.148.357.22.75.22 1.18 0
     .34-.05.662-.15.965-.1.303-.244.58-.434.826-.19.247-.422.464-.7.65-.277.188-.593.337-.948.45.238.134.443.328.616.58l2.534
     3.738H9.126c-.163
     0-.302-.033-.416-.098-.115-.065-.212-.16-.29-.28l-2.13-3.24c-.078-.122-.166-.21-.26-.26-.097-.05-.238-.077-.425-.077H4.8zm0-1.35h1.176c.355
     0 .664-.045.928-.134.263-.09.48-.21.65-.367.17-.157.298-.342.382-.557.084-.216.126-.45.126-.708
     0-.513-.17-.908-.507-1.183-.34-.276-.856-.414-1.55-.414H4.8v3.36zm9.345
     5.305h-1.89V19h1.89v10.122zm11.263-5.06c0 .74-.124 1.422-.37 2.043-.248.62-.596 1.155-1.044
     1.603-.448.448-.987.796-1.617 1.043-.63.248-1.328.372-2.093.372H16.42V19h3.864c.765 0 1.463.125
     2.093.375.63.25 1.17.597 1.617 1.043.448.445.796.978 1.043 1.6.247.62.37 1.3.37 2.043zm-1.925
     0c0-.556-.075-1.054-.224-1.495-.15-.442-.363-.815-.638-1.12-.275-.306-.61-.54-1.005-.704-.394-.163-.838-.245-1.333-.245h-1.967v7.126h1.967c.495
     0 .94-.082 1.334-.245.394-.164.73-.4 1.004-.704.275-.306.488-.68.637-1.12.148-.442.223-.94.223-1.495zM33.27
     19v1.498H28.78v2.807h3.535v1.45h-3.535v2.862h4.487v1.505h-6.385V19h6.384z"
    },
    {:twitter,
     "M153.62,301.59c94.34,0,145.94-78.16,145.94-145.94,0-2.22,0-4.43-.15-6.63A104.36,104.36,0,0,0,325,122.47a102.38,102.38,0,0,1-29.46,8.07,51.47,51.47,0,0,0,22.55-28.37,102.79,102.79,0,0,1-32.57,12.45,51.34,51.34,0,0,0-87.41,46.78A145.62,145.62,0,0,1,92.4,107.81a51.33,51.33,0,0,0,15.88,68.47A50.91,50.91,0,0,1,85,169.86c0,.21,0,.43,0,.65a51.31,51.31,0,0,0,41.15,50.28,51.21,51.21,0,0,1-23.16.88,51.35,51.35,0,0,0,47.92,35.62,102.92,102.92,0,0,1-63.7,22A104.41,104.41,0,0,1,75,278.55a145.21,145.21,0,0,0,78.62,23"
    },
    {:facebook,
     "M40.43,21.739h-7.645v-5.014c0-1.883,1.248-2.322,2.127-2.322c0.877,0,5.395,0,5.395,0V6.125l-7.43-0.029  c-8.248,0-10.125,6.174-10.125,10.125v5.518h-4.77v8.53h4.77c0,10.947,0,24.137,0,24.137h10.033c0,0,0-13.32,0-24.137h6.77  L40.43,21.739z"
    },
    {:nineoneone,
    "M45.638 100C41.56 88.692 29.16 86.465 19.293 84.146c-8.095-1.902-14.417-6.61-17.25-13.75-7.117-15.685 6.495-27.43 8.383-41.732.944-7.046-3.155-12.574-7-17.94l6.54-7.464C20.836 8.81 36.08 7.394 45.638 0c9.56 7.394 24.802 8.82 35.672 3.27l6.542 7.46c-3.848 5.367-7.946 10.895-7 17.943 1.888 14.303 15.5 26.048 8.382 41.732-2.832 7.14-9.154 11.846-17.25 13.75-9.87 2.32-22.27 4.537-26.346 15.845z"
    },
    {:calendar,
    "M17 7h2c.552 0 1 .456 1 1.002v9.996C20 18.55 19.555 19 19 19H5c-.552 0-1-.456-1-1.002V8.002C4 7.45 4.445 7 5 7h2v-.99C7 5.45 7.444 5 8 5c.552 0 1 .443 1 1.01V7h6v-.99C15 5.45 15.444 5 16 5c.552 0 1 .443 1 1.01V7zM5 10v2h2v-2H5zm0 3v2h2v-2H5zm0 3v2h2v-2H5zm3-6v2h2v-2H8zm0 3v2h2v-2H8zm0 3v2h2v-2H8zm3-3v2h2v-2h-2zm0 3v2h2v-2h-2zm0-6v2h2v-2h-2zm3 3v2h2v-2h-2zm0 3v2h2v-2h-2zm0-6v2h2v-2h-2zm3 3v2h2v-2h-2zm0 3v2h2v-2h-2zm0-6v2h2v-2h-2z"
    },
    {:direction,
      "M17 6v2H4v2h13v2l3-3-3-3zM7 12l-3 3 3 3v-2h13v-2H7v-2z"
    },
    {:variation,
     "M4.36396103,2.94974747 L6.48528137,0.828427125 L0.828427125,0.828427125 L0.828427125,6.48528137 L2.94974747,4.36396103 L4.50467854,5.9188921 L5.9188921,4.50467854 L4.36396103,2.94974747 Z
     M11.2928932,4.12132034 L13.6568542,6.48528137 L13.6568542,0.828427125 L8,0.828427125 L9.87867966,2.70710678 L7.70314358,4.88264285 C6.73486856,5.85091787 6,7.62414457 6,8.99810135 L6,15 L8,15 L8,8.99810135 C8,8.15470712 8.52406334,6.89015022 9.11735715,6.29685642 L11.2928932,4.12132034 Z"},
    {:parking_lot,
    "M10.544,13.176 L10.544,17.464 L9,17.464 L9,6 L12.384,6 C13.109337,6 13.7399973,6.08399916 14.276,6.252 C14.8120027,6.42000084 15.2559982,6.65866512 15.608,6.968 C15.9600018,7.27733488 16.2226658,7.65066448 16.396,8.088 C16.5693342,8.52533552 16.656,9.01333064 16.656,9.552 C16.656,10.085336 16.5626676,10.5733311 16.376,11.016 C16.1893324,11.4586689 15.9160018,11.8399984 15.556,12.16 C15.1959982,12.4800016 14.749336,12.7293324 14.216,12.908 C13.682664,13.0866676 13.0720034,13.176 12.384,13.176 L10.544,13.176 Z M10.544,11.944 L12.384,11.944 C12.8266689,11.944 13.2173316,11.8853339 13.556,11.768 C13.8946684,11.6506661 14.1786655,11.4866677 14.408,11.276 C14.6373345,11.0653323 14.8106661,10.8133348 14.928,10.52 C15.0453339,10.2266652 15.104,9.90400176 15.104,9.552 C15.104,8.82132968 14.8786689,8.25066872 14.428,7.84 C13.9773311,7.42933128 13.2960046,7.224 12.384,7.224 L10.544,7.224 L10.544,11.944 Z
    M2,2.00494659 C2,0.897645164 2.89821238,0 3.99079514,0 L20.0092049,0 C21.1086907,0 22,0.897026226 22,2.00494659 L22,21.9950534 C22,23.1023548 21.1017876,24 20.0092049,24 L3.99079514,24 C2.89130934,24 2,23.1029738 2,21.9950534 L2,2.00494659 Z M3,2.991155 L3,21.008845 C3,22.1103261 3.8932319,23 4.99508929,23 L19.0049107,23 C20.1073772,23 21,22.1085295 21,21.008845 L21,2.991155 C21,1.88967395 20.1067681,1 19.0049107,1 L4.99508929,1 C3.8926228,1 3,1.89147046 3,2.991155 Z"},
    {:mattapan_trolley,
    "M2 13V2.995C2 2.445 2.456 2 3.002 2h9.996C13.55 2 14 2.456 14 2.995V13c0 .552-.456 1-1.002 1H3.002A.999.999 0 0 1 2 13zm2.667 1h6.666L12 16H4l.667-2zM4 1c0-.552.453-1 .997-1h6.006c.55 0 .997.444.997 1v1H4V1zm0 2.5c0 .268.224.5.5.5h7c.27 0 .5-.224.5-.5 0-.268-.224-.5-.5-.5h-7c-.27 0-.5.224-.5.5zM3 6v3c0 .556.452 1 1.01 1h1.98A1 1 0 0 0 7 9V6c0-.556-.452-1-1.01-1H4.01A1 1 0 0 0 3 6zm6 0v3c0 .556.452 1 1.01 1h1.98A1 1 0 0 0 13 9V6c0-.556-.452-1-1.01-1h-1.98A1 1 0 0 0 9 6zm-2 6c0 .556.448 1 1 1 .556 0 1-.448 1-1 0-.556-.448-1-1-1-.556 0-1 .448-1 1z"},
    {:fare_ticket, "M3.02150184,1.90018149 L17.0215018,1.90018149 C17.5737866,1.90018149 18.0215018,2.34789674 18.0215018,2.90018149 L18.0215018,10.9001815 C18.0215018,11.4524662 17.5737866,11.9001815 17.0215018,11.9001815 L3.02150184,11.9001815 C2.46921709,11.9001815 2.02150184,11.4524662 2.02150184,10.9001815 L2.02150184,2.90018149 L2.02150184,2.90018149 C2.02150184,2.34789674 2.46921709,1.90018149 3.02150184,1.90018149 L3.02150184,1.90018149 Z M2.02150184,3.90018149 L2.02150184,5.90018149    L18.0215018,5.90018149 L18.0215018,3.90018149 L2.02150184,3.90018149 Z"
    }] |> Map.new

  def variants do
    # remove the default icon
    other_icons = Map.drop(@icons, [%__MODULE__{}.icon])
    for {icon, _path} <- other_icons do
      {icon_title(icon),
       %__MODULE__{
         icon: icon
       }}
    end
  end

  def get_path(atom) when atom in [:green_line, :red_line, :blue_line, :orange_line], do: get_path(:t_logo)
  def get_path(atom) when is_atom(atom) do
    @icons
    |> Map.get(atom)
    |> String.replace(~r/\n/, "")
    |> String.replace(~r/\t/, "")
    |> String.replace(~r/\s\s/, " ")
    |> build_path
  end
  def get_path(arg), do: get_path(get_icon_atom(arg))

  @spec get_icon_atom(icon_arg) :: atom
  def get_icon_atom(arg) when is_atom(arg), do: arg
  def get_icon_atom("Elevator"), do: :access
  def get_icon_atom("Escalator"), do: :access
  def get_icon_atom(route_type) when route_type in [0,1,2,3,4], do: Routes.Route.type_atom(route_type)
  def get_icon_atom(%Routes.Route{} = route), do: Routes.Route.icon_atom(route)
  def get_icon_atom(arg) when is_binary(arg) do
    arg
    |> String.downcase
    |> String.replace(" ", "_")
    |> String.to_atom
  end

  @spec icon_title(atom) :: String.t
  def icon_title(:alert), do: "Service alert or delay"
  def icon_title(:parking_lot), do: "Parking"
  def icon_title(icon) when icon in [:subway, :bus, :commuter_rail, :ferry] do
    Site.ViewHelpers.mode_name(icon)
  end
  def icon_title(icon) do
    "#{icon} icon"
  end

  def build_path(path) do
    Phoenix.HTML.Tag.content_tag(:path, d: path) do
      []
    end
  end

  def viewbox(:map), do: "0 0 26 24"
  def viewbox(:alert), do: "0 0 24 24"
  def viewbox(:the_ride), do: "0 0 36 36"
  def viewbox(:twitter), do: "0 0 400 400"
  def viewbox(:facebook), do: "0 0 75 75"
  def viewbox(:parking_lot), do: "0 0 24 24"
  def viewbox(:search), do: "6 -4 95 95"
  def viewbox(icon) do
    if icon in mode_icons(), do: "0 0 16 16", else: "0 0 40 40"
  end

  def unoptimized_paths, do: @icons

  def mode_icons, do: @mode_icons
end
