# Godot VR Shooting Range

Ein einfaches VR-Spiel erstellt mit Godot 4.3 und OpenXR.

## Features

- ✅ VR-Unterstützung (OpenXR) für Meta Quest, SteamVR, etc.
- ✅ Begehbarer Raum mit Wänden
- ✅ Aufhebbare Waffe
- ✅ Schießmechanik mit Raycast
- ✅ Zielobjekte an der Wand
- ✅ Muzzle Flash Effekt

## Installation

1. **Godot 4.3+ herunterladen**
   - https://godotengine.org/download

2. **Projekt öffnen**
   - Godot starten
   - "Import" klicken
   - `project.godot` auswählen

3. **OpenXR Plugin aktivieren**
   - Projekt → Projekteinstellungen → Plugins
   - "OpenXR" aktivieren

## VR Setup

### Meta Quest
1. Quest mit PC verbinden (Link-Kabel oder Air Link)
2. Oculus Software starten
3. In Godot: Play-Button drücken

### SteamVR
1. SteamVR starten
2. Headset verbinden
3. In Godot: Play-Button drücken

## Steuerung

- **Bewegung**: Physische Bewegung im Raum
- **Waffe aufheben**: Controller in Nähe der Waffe bewegen
- **Schießen**: Trigger-Taste am Controller

## Projektstruktur

```
godovr-pietro/
├── scenes/
│   ├── main.tscn          # Hauptszene
│   ├── room.tscn          # Raum mit Wänden und Zielen
│   └── gun.tscn           # Waffe
├── scripts/
│   ├── xr_setup.gd        # VR-Initialisierung
│   └── gun.gd             # Waffen-Logik
└── project.godot          # Projekt-Konfiguration
```

## Erweiterungsideen

- [ ] Verschiedene Waffen
- [ ] Zerstörbare Ziele mit Score
- [ ] Teleportation für größere Räume
- [ ] Sound-Effekte
- [ ] Particle-Effekte
- [ ] Mehrere Levels

## Technische Details

- **Engine**: Godot 4.3
- **Renderer**: OpenGL Compatibility
- **VR**: OpenXR
- **Sprache**: GDScript

## Troubleshooting

**VR startet nicht:**
- OpenXR Plugin aktiviert?
- Headset verbunden?
- SteamVR/Oculus Software läuft?

**Waffe lässt sich nicht aufheben:**
- Controller-Tracking funktioniert?
- Näher an die Waffe herangehen

**Performance-Probleme:**
- Renderer auf "gl_compatibility" gestellt?
- VRS aktiviert in Projekteinstellungen?

## Lizenz

MIT License - Frei verwendbar für private und kommerzielle Projekte.