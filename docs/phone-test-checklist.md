# Phone test checklist: E-LIKAS 0.4.0+9

For testing on a real phone against the backend with the November 22-24
changes (docs/backend/apps-api-2026-11-22.md, apps-api-2026-11-23.md,
push-notifications.md). Each line is one thing to try and what you
should see. Run the event items in order; the others can go in any order.

You need: one barangay official account (one with a temporary password
too), one CSWD account with `events.manage`, the web open as CSWD, and a
second phone or the emulator for the resident app. Use the practice
events ("Typhoon Drill" active, "Incoming Typhoon" monitoring): they
never send pushes.

## 1. Compatibility

- [ ] No "DEMO" or "DRILL" mark anywhere: event line, event switcher,
      EC Board event picker, Monitoring, resident Home.
- [ ] A center at 80-89% shows the amber **Nearly full** chip (list, map
      legend, EC Board).
- [ ] Numbers over 999 have separators ("1,669 persons"); durations read
      "3 days", "1 hour"; times read "Nov 19, 1:44 AM"; "1 family" but
      "2 families".
- [ ] A refused change because of the event (for example, a queued
      handout when the event was closed meanwhile) shows a grey lock and
      the server's own sentence, in Sync and in the snack bar, not a red
      error.

## 2. Event lifecycle (barangay official)

- [ ] Select **Incoming Typhoon** (Monitoring). Home shows the lock
      "Available when the event is Active" and **Families are arriving**.
- [ ] Register family, Give relief box: shown with a lock and not
      tappable. Register (if opened another way) shows the lock, no form.
- [ ] EC Board: no Add Evacuee, no Returning families, no "Ask another
      center for space"; the lock instead.
- [ ] Relief tab: the lock and the Round 1 plan (boxes, and "from your
      list" or "from the forecast").
- [ ] Final count card: the lock instead of Submit. Transfers: the lock
      instead of Accept / Decline.
- [ ] **Families are arriving** in airplane mode: "Needs a connection",
      nothing saved. Online: the dialog with an optional note, then "CSWD
      was told." CSWD sees the notification on the web.
- [ ] On the web (CSWD), start the evacuation of Incoming Typhoon. Pull
      to refresh: the event turns Active, the green "Registration is
      open" card shows, and the phone shows its own "Registration is
      open" notification (Staff Mode channel).
- [ ] Sign out and in again with two open events: the Active one is
      selected first.

## 3. Official home

- [ ] Plan: **Plan for** (families, persons, the forecast range; "Above
      anything seen before" when the server says so), **Your list** (opens
      Families to evacuate), **Center space vs forecast** (short in red or
      enough in green), **Centers ready** ("2 of 4").
- [ ] For a volcanic event, Plan for says "No forecast for volcanic events
      yet. Plan using the barangays inside the danger zone."
- [ ] Barangay status card: "Updated 3 hours ago" and **Change status**
      (opens the barangay page).
- [ ] To do lists the server's items as they come: capacity missing or
      estimated, map location, facilities checklist (each opens My
      centers), supplies short with **Request supplies** (opens Facility
      requests).
- [ ] Alerts: only city-wide alerts and your own barangay's, each with
      Emergency / Advisory / Info and **New** until you open it.

## 4. Families to evacuate

- [ ] The list is grouped by purok, high-risk puroks first with a red
      "High risk" chip, and says a listed family is not an evacuee.
- [ ] Add family > From past events: search a name, tap a family; it is
      added with its household. Add family > New family: head's names,
      sex, members (1-30), purok, contact, note.
- [ ] Remove (the "..." menu) works only for families not checked in.
- [ ] High-risk puroks (warning icon in the bar): switch flood /
      landslide; the list re-sorts.
- [ ] Monitoring: each family shows a lock, no Check in.
- [ ] Active, airplane mode: **Check in** > a center (a pending one says
      "Pending CSWD approval") or a private house (host name and purok or
      address). The row says "Waiting to sync". Back online it syncs once;
      on the web the family is registered, with named members copied.

## 5. Centers

- [ ] My centers and the EC Board list: capacity with "est." for an
      estimate, a fill bar in the status colour, no bar for an unknown
      capacity, and "Needs details:" chips (Capacity, Capacity is an
      estimate, Map location, Facilities checklist).
- [ ] A center's page: **Use my current location** asks for the location
      permission the first time, shows the point and its accuracy, then
      queues it. As an official of an approved center it says CSWD
      approves it; as CSWD it is saved at once.
- [ ] **Pick on the map**: drag the map under the pin (street or
      satellite), **Use this point**, confirm.
- [ ] The location line shows "Set by CSWD" / "Set by barangay official" /
      "Original data" when the server sends it.
- [ ] Active event, Register family, step 3: your pending center is listed
      with "Pending CSWD approval", and choosing it shows the warning.
      Save: CSWD gets the urgent notification on the web.

## 6. Inside a center (EC Board)

- [ ] Each family on "Families here" has a "..." menu with **Check out**
      and **Transfer**.
- [ ] Transfer > one of your other centers: confirm (optional reason),
      online only; the family moves at once.
- [ ] Transfer > "Ask another barangay's center": the transfer request
      screen.
- [ ] Fill a center to 90% or more: "This center is 92% full" and **Ask
      another center for space**; below 90% (or with an unknown capacity)
      it does not show.

## 7. Relief boxes

- [ ] Families show "Priority: PWD / senior" (or the server's label).
- [ ] Only the family marked "Next in line" has the filled Give button;
      the others have an outlined Give that still warns when out of order.
- [ ] Before the count is validated: "Need (registered)" and "Need based
      on the registered count, not yet validated. Boxes can already be
      given."
- [ ] A family from another barangay staying here shows "From
      <barangay>" and can be given its box. On its home barangay's list it
      has no Give button ("Staying in <barangay>: they give the box").

## 8. Facility requests

- [ ] Request supplies (or "+" on Facility requests): item, quantity,
      unit, reason. Works offline (queued).
- [ ] "Suggested for your centers": each row with **Send**.
- [ ] A sent request shows **Mark received** (confirm, queued); a request
      approved for fewer shows "Approved 6 of 10".
- [ ] A received or rejected request shows **Request again**, with the
      form filled in.

## 9. Final counts

- [ ] After CSWD validates the count with nothing new: "Submit updated
      count" is greyed with "Nothing new since your validated count".
- [ ] Register one more family: the late-entry chips appear (added,
      since <time>) and Submit is back.
- [ ] CSWD submits on behalf (web, with a reason): the card shows
      "Submitted by CSWD on behalf of ... Reason: ...".

## 10. Account and system

- [ ] Sign in with the username (`brgy.<barangay>`): the field says
      "Email or username" and accepts it.
- [ ] An account with a temporary password: "Choose your password" comes
      first; under 10 characters or the same password is refused; after
      saving, Staff Mode opens. Other phones signed in to it are signed
      out.
- [ ] Five wrong passwords: the lock look with the server's message
      (when to try again).
- [ ] Maintenance on (administrator): the sign-in screen shows its
      message with the lock look; signed-in screens show it on refusal.
- [ ] A system notice (administrator) shows as a banner at the top of
      Staff Mode; the X hides it until the next start.
- [ ] More > **Report a problem**: what happened (10+ characters), the
      screen, a photo from the camera and from the gallery (both ask for
      their permission), the privacy reminder. Send: the report appears
      under "Your reports"; the administrator's reply shows there later.
- [ ] Administrator > Devices and sync: this phone with its app version
      0.4.0, platform mobile, records waiting / failed and the last sync.
      Sign the device out there: the app goes back to sign-in.

## 11. CSWDO

- [ ] Select Incoming Typhoon: Home shows **Start evacuation**. Airplane
      mode: "Needs a connection". Online: the confirm dialog, then the
      event is Active and officials get "Registration is open".
- [ ] **Evacuation progress**: per barangay "6 of 12 expected families
      registered" and "5 of 12 listed families checked in", behind first;
      a barangay with no list says so.
- [ ] A barangay page: **Ask barangay to update** (confirm, online); the
      official gets the notification.
- [ ] A barangay with an official and no validated count: **Remind final
      count** (confirm, online).
- [ ] CSWD never sees Register, Check out or Add Evacuee.

## 12. Residents (no sign-in)

- [ ] Record a Preemptive (then Forced) order for the phone's barangay:
      Home shows the large orange (then red) banner with "Nearest open
      centers".
- [ ] Alerts tab: city-wide alerts and your barangay's only (send one to
      another barangay: it does not show), with Emergency / Advisory /
      Info and **New** until opened.
- [ ] Home: the three nearest safe centers, never Full or Closed, with
      "(estimated)" capacities and Directions to Google Maps. For a
      volcanic event, none within 7 km of Mayon.
- [ ] Hazards card: "inside the 6 km / 7 km zone" or "N km from the
      summit", with the PHIVOLCS note.
- [ ] Be prepared: the go-bag and three more checklists, each naming its
      agency and "for team review"; ticks stay after closing the app; it
      all works in airplane mode.
- [ ] Family emergency plan: fill it in, save, close the app, reopen: it
      is still there. (It is never sent: nothing appears on the server.)
- [ ] Settings > Language: Filipino and Bikol; Bikol shows the new
      resident screens in Bikol.
- [ ] Settings > Text size: Large and Larger make every screen's text
      bigger, on top of the phone's own size.

## 13. Push notifications (resident phone)

- [ ] First start: the reason ("E-LIKAS tells you about emergency alerts
      and evacuation orders for your barangay"), then Android 13+'s own
      prompt. Allow.
- [ ] Settings > tap **Version** seven times: "Receive test
      notifications" appears; switch it on.
- [ ] Administrator > System > Health > **Send test push**: "E-LIKAS test
      notification" within a few seconds, app closed. Tap: Home opens.
- [ ] Same with the app open: the app shows the notification itself.
- [ ] The notification channel in Android settings is "Emergency alerts
      and evacuation orders", high importance.
- [ ] (Real event only, coordinated with CSWD) an Emergency alert opens
      that alert; an evacuation order opens the nearest open centers.
- [ ] Move to another barangay (or fake the location): the phone stops
      getting the old barangay's pushes and gets the new one's.
