# Rebuild Progress Checklist

Tick an item only after you have run and explained it yourself.

## Setup

- [ ] Create the new web project folder.
- [ ] Install the frontend dependencies.
- [ ] Start the development server.
- [ ] Open the empty page in a browser.

## Layout

- [ ] Create the sidebar.
- [ ] Create the top bar.
- [ ] Add Overview, Assets, Schedules, and Institutions navigation.
- [ ] Make navigation change the visible section.

## Data and API

- [ ] Define all TypeScript types.
- [ ] Create the API proxy.
- [ ] Create the reusable `api()` function.
- [ ] Load assets and institutions.
- [ ] Display loading and error states.
- [ ] Add a Refresh button.

## Overview

- [ ] Count total assets.
- [ ] Count available assets.
- [ ] Count loans and bookings.
- [ ] Identify overdue schedules.
- [ ] Display recent assets.
- [ ] Display overdue items.

## Assets

- [ ] Display the asset table.
- [ ] Add status labels.
- [ ] Add text search.
- [ ] Add institution filtering.
- [ ] Open an asset details drawer.
- [ ] Create a new asset.
- [ ] Delete a test asset.

## Activities

- [ ] Loan an available asset.
- [ ] Return a loaned asset.
- [ ] Book an available room or lab.
- [ ] Release an occupied resource.

## Schedules

- [ ] Display all schedules.
- [ ] Mark overdue schedules.
- [ ] Add a schedule.
- [ ] Update a schedule.
- [ ] Delete a schedule.

## Institutions

- [ ] Display institution cards.
- [ ] Display sites/campuses.
- [ ] Count assets per institution.
- [ ] Count available and maintenance assets.

## Optional full API coverage

- [ ] Manage asset components.
- [ ] Create and update work orders.
- [ ] Add and complete work-order tasks.
- [ ] Add and remove institutions.
- [ ] Add and remove institution sites.

## Styling

- [ ] Define the colour variables.
- [ ] Style buttons and form controls.
- [ ] Style the dashboard cards.
- [ ] Style the table and status labels.
- [ ] Style modals and the details drawer.
- [ ] Add loading and success messages.
- [ ] Add tablet styling.
- [ ] Add mobile styling.

## Final testing

- [ ] Test while Ballerina is running.
- [ ] Test the error state while Ballerina is stopped.
- [ ] Test create and delete through the website.
- [ ] Test loan and booking status changes.
- [ ] Test schedule creation.
- [ ] Run the production build.
- [ ] Explain the browser-to-proxy-to-Ballerina request flow without notes.
