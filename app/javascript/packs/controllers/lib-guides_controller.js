import { Controller } from "stimulus"

export default class extends Controller {
    static targets = [ "librarian", "guides" ];

    simpleParagraph(text) {
	var p = document.createElement('p');
	p.textContent = text;
	return p;
    }

    load() {
	var url = this.data.get('api-url');
	var $this = this;
	var listTemplate = document.querySelector('#lib-guides-list');
	fetch(url)
	    .then(response => response.json())
	    .then(function(data) {
		// librarian section
		let owner = data[0].owner;
		let ownerLink = document.createElement('a');
		ownerLink.href = "https://guides.temple.edu/prf.php?account_id=" + owner.id
		ownerLink.textContent = owner.first_name + " " + owner.last_name;
		let ownerP = document.createElement('p');
		ownerP.appendChild(ownerLink);
		$this.librarianTarget.appendChild(ownerP);
		['title', 'email'].forEach(function(property) {
		    if (owner.hasOwnProperty(property) && owner[property]) {
			$this.librarianTarget.appendChild(
			    $this.simpleParagraph(owner[property]));
		    }
		});
		// guides list section
		var list = listTemplate.content.cloneNode(true);
		var li = list.querySelectorAll("li");
		data.forEach(function(item, i) {
		    li[i].textContent = "";
		    let link = document.createElement('a');
		    link.href = item.url;
		    link.textContent = item.name;
		    li[i].appendChild(link);
		});
		$this.guidesTarget.appendChild(list);
	    });
    }

    connect() {
	this.load();
    }
}
