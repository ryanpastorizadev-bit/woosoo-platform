---
status: archived
original_date: 2024-05
archived: 2026-05-27
scope: origin-specification
archived_reason: Historical specification document; the Kitchen Display System component described in Section 3 was subsequently replaced by the Woosoo Print Bridge (Flutter Android relay).
---

# Table Ordering App with Kitchen Display — Original Specification

**Prepared for:** Woosoo KBBQ  
**Prepared by:** Ryan H. Pastoriza  
**Date:** MAY 20XX

---

## Editorial Note

This is the original signed specification for the Woosoo KBBQ digital transformation project, dated May 20XX. It represents the initial requirements and scope agreement. Please note that **Section 3 (Kitchen Display System)** describes a legacy KDS component that was subsequently architected and replaced by the **Woosoo Print Bridge** — a production Flutter Android relay service built for restaurant-grade print job reliability and Reverb broadcast integration. The core functional objectives, payment terms, and stakeholder agreements remain accurately reflected herein.

---

## Executive Summary

Woosoo KBBQ is initiating a digital transformation project to improve the dine-in restaurant experience through a table ordering system. The goal is to minimize manual order errors, speed up service, and provide remote access to real-time business data. The system consists of a tablet interface for customers, a kitchen display system for staff, and a cloud-synced Laravel backend for administrators.

**Signed as accepted by client:** [NAME], [TITLE], [DATE]

---

## Project Overview

This project involves developing a tablet-based ordering system integrated with a Laravel API backend and a cloud-hosted server. It includes a Nuxt.js-based customer interface for each table, a Kitchen Display System (KDS), and an administrative dashboard. The system supports both offline and online modes, using local storage for transaction queuing and automatic cloud syncing. Additional features include QR code-based access and remote live sales reporting.

### Business Objectives / Goals

- Minimize order-taking errors and improve order processing speed.
- Enhance the customer dining experience through self-service.
- Streamline restaurant operations between the dining area, kitchen, and staff.
- Enable future scalability, including online ordering, marketing tools, and loyalty programs.

---

## Scope

### In-Scope

- Tablet ordering app per table
- Offline transaction queueing and cloud sync
- Kitchen display system integration
- 3rd Party POS integration
- Remote access to sales and closing data
- Admin dashboard

### Out-of-Scope (MVP)

- Online ordering (web or mobile)
- Payment processing via tablet
- Loyalty Awards

---

## Stakeholders

- **Project Owner:** Woosoo KBBQ Management
- **Development Team**
- **Restaurant Staff**

---

## Requirements

### Functional Requirements

- Tablet interface per table with no login required
- Digital menu with photos, categories, and modifiers
- Tap-to-order and quantity selection
- Order summary, confirmation, and live status updates
- Buttons for calling staff: service, water, billing, cleanup
- Kitchen Display System with color-coded status and ticket management
- Admin dashboard for menu and order management
- Cloud dashboard for real-time and end-of-day sales viewing

### Non-Functional Requirements

- Operates on local network with offline capabilities
- Queued transactions stored locally and synced to cloud server
- Responsive design and optimized performance for tablets
- Custom branding and theming to match Woosoo's identity

---

## Workflow Overview

### Customer Tablet Interface

- Customer browses digital menu with images and categories
- Customer selects items, adds modifiers and quantities, and places order
- Order is stored locally and sent to backend via LAN
- Order status (e.g., Preparing, Served) updates live on the tablet
- Buttons available to call for service, water, billing, or cleanup

### Kitchen Display System (KDS)

- Receives real-time orders from customer tablets
- Displays itemized tickets with modifiers
- Tickets color-coded by status (new, in progress, completed)
- Staff can tag orders as "In Progress" or "Completed"

### Admin Backend

- Monitor real-time and historical order data
- User and role management
- View reports by table, item, or time period
- Cloud access for viewing live and end-of-day sales data

---

## Obstacles & Challenges

- Resistance to change from staff and customers
- Training requirements for all employees
- Hardware maintenance and consistency
- Downtime during peak hours if hardware fails
- Managing tablet battery life and connectivity

---

## Assumptions

- Restaurant has or will install a stable local network
- Management will provide devices and ensure power access at tables
- Users will accept and use digital ordering once trained
- Sync retries will be sufficient to prevent data loss

---

## Project Cost

This project will be handled by a 3-man development team and is priced as a one-time project.

**Total development cost:** ₱350,000.00

---

## Payment Terms

To ensure a structured and transparent development process, the following payment terms are proposed:

| Milestone | Percentage | Description |
|---|---|---|
| 1 | 30% | Project Kickoff and approval |
| 2 | 30% | MVP Delivery (Minimum Viable Product) |
| 3 | 30% | Final Delivery |
| 4 | 10% | Post-Launch Support |

### Inclusions

- Source code and documentation upon full payment.
- Free bug fixing and technical support post-deployment (24 months).
- Additional support and feature updates can be contracted separately.
