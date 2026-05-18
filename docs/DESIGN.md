---
name: Humane Modernity
colors:
  surface: '#f8f9fb'
  surface-dim: '#d9dadc'
  surface-bright: '#f8f9fb'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f4f6'
  surface-container: '#edeef0'
  surface-container-high: '#e7e8ea'
  surface-container-highest: '#e1e2e4'
  on-surface: '#191c1e'
  on-surface-variant: '#5a413d'
  inverse-surface: '#2e3132'
  inverse-on-surface: '#f0f1f3'
  outline: '#8e706c'
  outline-variant: '#e2bfb9'
  surface-tint: '#b22b1d'
  primary: '#570000'
  on-primary: '#ffffff'
  primary-container: '#800000'
  on-primary-container: '#ff8371'
  inverse-primary: '#ffb4a8'
  secondary: '#605e5b'
  on-secondary: '#ffffff'
  secondary-container: '#e6e2dd'
  on-secondary-container: '#666460'
  tertiary: '#2a2620'
  on-tertiary: '#ffffff'
  tertiary-container: '#403c35'
  on-tertiary-container: '#ada69d'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad4'
  primary-fixed-dim: '#ffb4a8'
  on-primary-fixed: '#410000'
  on-primary-fixed-variant: '#8f0f07'
  secondary-fixed: '#e6e2dd'
  secondary-fixed-dim: '#c9c6c1'
  on-secondary-fixed: '#1c1c19'
  on-secondary-fixed-variant: '#484743'
  tertiary-fixed: '#e9e1d7'
  tertiary-fixed-dim: '#cdc5bc'
  on-tertiary-fixed: '#1e1b15'
  on-tertiary-fixed-variant: '#4a463f'
  background: '#f8f9fb'
  on-background: '#191c1e'
  surface-variant: '#e1e2e4'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 41px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 25px
  body-base:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 21px
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 20px
  gutter: 16px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style
This design system establishes a visual language that balances the institutional prestige of UTM with the gentle, nurturing nature of animal welfare. The brand personality is rooted in "humane professionalism"—avoiding the clinical coldness of tech while maintaining a sophisticated, high-end mobile aesthetic. 

The style draws heavily from **Apple Human Interface** principles, utilizing generous whitespace, depth through layering, and a clear visual hierarchy. By blending **Minimalism** with subtle **Glassmorphism**, the UI feels airy and responsive. The emotional goal is to evoke a sense of calm and trust, ensuring that users feel empowered to take action in stressful situations (like reporting an injured stray) or feel warmth when browsing adoption profiles.

## Colors
The palette is led by **UTM Maroon**, used strategically for primary actions and brand presence to maintain an institutional connection. The foundation of the UI is built on **Warm Cream** and **Soft Beige**, which provide a much softer, more "humane" alternative to pure white, reducing eye strain and creating a welcoming atmosphere.

**Light Gray** is utilized for subtle backgrounds and grouping elements. For functional feedback, **Emergency Red** is reserved strictly for high-priority alerts (injured animals, urgent needs), while **Success Green** signals completed actions and positive outcomes. The color application must remain "high-breathing," ensuring the maroon never overwhelms the delicate cream base.

## Typography
This design system utilizes **Inter** to emulate the clarity and systematic feel of SF Pro. The typographic hierarchy is designed for mobile-first scanning. **Display** and **Headline** levels use heavy weights and slight negative letter spacing to create a modern, editorial feel characteristic of high-end mobile OS interfaces.

Body text is prioritized for legibility, using a slightly larger base size (17px) and generous line height to ensure accessibility. **Labels** utilize uppercase styling only for small metadata tags to maintain a clean, organized look without appearing "loud."

## Layout & Spacing
The layout follows a **Bento-grid** philosophy, grouping information into distinct, modular units that fit together logically. This is highly effective for animal profiles where varied data (age, health status, location) needs to be consumed quickly.

The system uses a **4px baseline rhythm**. Standard mobile page margins are set to **20px** to provide more breathing room than standard 16px layouts, reinforcing the "calm" vibe. Gutters between grid items are fixed at **16px**. Elements should favor vertical stacking in a single column for core content, moving to 2-column bento tiles for secondary metrics.

## Elevation & Depth
Depth is achieved through **Tonal Layers** and **Ambient Shadows**. Instead of traditional drop shadows, this design system uses highly diffused, low-opacity shadows with a subtle tint of the primary color to make elements feel "airy" rather than heavy.

**Glassmorphism** is applied to floating navigation bars and top headers to maintain context of the content underneath. Use a `backdrop-filter: blur(20px)` with a `60%` opacity white or cream fill. Floating cards should have a distinct but soft elevation to indicate interactability, appearing as if they are resting gently on the Soft Beige background.

## Shapes
The shape language is defined by **16px rounded corners** for all primary containers and cards, creating a friendly and approachable feel. This "Soft/Rounded" approach avoids the sharpness of corporate systems while staying more professional than "Pill-shaped" toy-like aesthetics.

Smaller interactive elements like buttons and inputs use a slightly tighter **12px radius** to maintain visual balance. Chips and status tags are fully rounded (pill) to distinguish them clearly from interactive buttons.

## Components

### Buttons
Primary buttons use the **UTM Maroon** with white text, featuring a subtle inner glow rather than a heavy shadow. Secondary buttons are semi-transparent Soft Beige with Maroon text. All buttons have a height of at least 48px to ensure touch-target compliance.

### Cards & Bento Grid
Cards are the primary container. They feature a white or light cream background, 16px border radius, and a 1px soft border in `#EFE7DD`. In a bento-grid layout, use varying heights to create visual interest while keeping the width consistent to the 20px margin container.

### Inputs & Fields
Input fields use a subtle Light Gray (`#F3F4F6`) fill with no border in their default state. Upon focus, they transition to a Soft Beige background with a 1.5px Maroon border. Labels sit outside the field in the `label-caps` style.

### Glass Navigation
The bottom navigation bar must use the glassmorphic treatment. Icons should be thin-stroke (Apple SF Symbols style) with a clear active state using a Maroon tint and a small dot indicator below the icon.

### Emergency Toggles
A specialized "Report Stray" component should be anchored or easily accessible, using a Soft Red background with Emergency Red text to signify urgency without inducing panic.