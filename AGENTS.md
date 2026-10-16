# AESTHETIC WAY — Project Rules for AI Agents

## Product
- Name: AESTHETIC WAY
- Market: UAE (Dubai & Abu Dhabi first)
- Type: Medical aesthetic & dermatology discovery + lead generation
- Platforms: Customer mobile app first (iOS/Android)

## Hard boundaries (DO NOT build)
- No patient payments / checkout / cart
- No full booking calendar
- No final appointment confirmation inside the app
- No home services
- No non-medical beauty salons
- No complex loyalty points

## Core allowed features
- Discover clinics, professionals, treatments, offers
- Google Maps integration (mandatory)
- Direct contact (call / WhatsApp)
- Appointment Request = Lead only
- Success text must be: "تم إرسال طلبك وستتواصل العيادة معك"
- Featured/Sponsored clinics by subscription tier
- Reviews, favorites, auth, consents

## Professionals
- Types: Doctor / Nurse / Licensed Professional
- Strict Client Rule: NO regulatory license numbers or authority names (DHA/DOH/MOHAP) in UI

## Subscription ads priority
1. VIP / 6-12 months: highest Home placement
2. Featured / 3-6 months: secondary
3. Basic / 1 month: normal listing only

## Design identity
- Dark navy/black backgrounds
- Silver/platinum accents
- Luxury medical aesthetic
- Arabic RTL primary + English LTR

## Source of truth docs & enforcement skills
- .agents/skills/strict_project_rules/SKILL.md
- docs/product/ui-ux-spec.md
- docs/product/scope.md