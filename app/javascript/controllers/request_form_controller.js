import { Controller } from "@hotwired/stimulus"

const descriptionPlaceholderLabel = "Select volume/issue or additional item details, if applicable"

export default class extends Controller {
  static targets = [ "pickups", "descriptions" ]

  connect() {
    this.descriptionGroups = this.hasDescriptionsTarget ? Array.from(this.descriptionsTarget.querySelectorAll("optgroup")).map((optgroup) => optgroup.cloneNode(true)) : []
    this.pickupGroups = this.hasPickupsTarget ? Array.from(this.pickupsTarget.querySelectorAll("optgroup")).map((optgroup) => optgroup.cloneNode(true)) : []
    this.booking_end_date()
    this.to_page()
  }

  resetPickupSelection() {
    if (!this.hasPickupsTarget) return

    $(this.pickupsTarget).prop("selectedIndex", 0)
  }

  hiddenOption(label = "") {
    return $("<option />")
      .attr("value", "")
      .text(label)
      .prop("disabled", true)
      .prop("selected", true)
      .prop("hidden", true)
  }

  replaceOptions(target, options) {
    $(target).empty().append(options)
  }

  filterPickupOptions(description) {
    if (!this.hasPickupsTarget) return

    let matchingPickupGroup = this.pickupGroups.find((optgroup) => optgroup.label === description);

    if(matchingPickupGroup) {
      let options = [this.hiddenOption()[0], ...Array.from(matchingPickupGroup.querySelectorAll("option")).map((option) => option.cloneNode(true))]
      this.replaceOptions(this.pickupsTarget, options)
    } else {
      this.resetPickupSelection();
    }
  }

  to_page() {
    $("#to_page").change(function() {
      $("#to_page").prop("min", $("#from_page").val());
    });  }

  booking_end_date() {
    $("#booking_start_date").change(function() {
      let dt = new Date($("#booking_start_date").val());
      dt.setDate(dt.getDate() + 8);
      let end = dt.toISOString().split("T")[0]
      $("#booking_end_date").prop("min", $("#booking_start_date").val());
      $("#booking_end_date").prop("max", end);
    });
  }

  select() {
    if (!this.hasDescriptionsTarget || !this.hasPickupsTarget) return

    let description = this.descriptionsTarget.options[this.descriptionsTarget.selectedIndex]?.text;
    this.filterPickupOptions(description)
  }

  typeSelect() {
    if (!this.hasDescriptionsTarget) return

    let material_type = $("#material_type option").filter(":selected").text();
    let matchingDescriptionGroup = this.descriptionGroups.find((optgroup) => optgroup.label === material_type);
    let descriptionOptions = matchingDescriptionGroup ? Array.from(matchingDescriptionGroup.querySelectorAll("option")) : [];

    if(descriptionOptions.length === 1) {
      this.replaceOptions(this.descriptionsTarget, descriptionOptions.map((option) => option.cloneNode(true)));
      $(this.descriptionsTarget).prop("selectedIndex", 0);
      this.filterPickupOptions(descriptionOptions[0].textContent);
    } else {
      if(descriptionOptions.length > 1) {
        let options = [this.hiddenOption(descriptionPlaceholderLabel)[0], ...descriptionOptions.map((option) => option.cloneNode(true))]
        this.replaceOptions(this.descriptionsTarget, options)
      } else {
        $(this.descriptionsTarget).prop("selectedIndex", 0);
      }
      this.resetPickupSelection();
    }
  }
}
