function scrollToTop() {
  window.scroll({
    top: 0,
    behavior: "smooth",
  });
}

function submitFormDefault(event) {
  event.preventDefault();
  return axios({
    method: event.target.method,
    url: event.target.action,
    data: new FormData(event.target),
    headers: { "Content-Type": event.target.enctype },
  });
}

function Form({ setItems }) {
  const onSubmit = (event) => {
    submitFormDefault(event).then((response) => {
      setItems(response.data);
      scrollToTop();
    });
  };

  return (
    <form
      method="post"
      action="/artworks/similar"
      encType="multipart/form-data"
      onSubmit={onSubmit}
      className="d-flex"
    >
      <input
        id="imageInput"
        name="image"
        type="file"
        accept=".jpg, .jpeg, .png, .gif"
        className="form-control me-2"
      />
      <button className="btn btn-light">Buscar</button>
    </form>
  );
}

function Artwork({ data, setItems }) {
  const [patternVisible, setPatternVisible] = React.useState(true);
  const [patternSize, setPatternSize] = React.useState(64);

  const onClick = () => {
    axios({
      method: "get",
      url: `/artworks/similar/${data.id}`,
    }).then((response) => {
      setItems(response.data);
      scrollToTop();
    });
  };

  return (
    <div className="card mb-3">
      <div className="row g-0">
        <div className="col-md-4">
          <div
            style={{
              backgroundImage: `url(${data.image_url})`,
              backgroundPosition: "center",
              backgroundRepeat: "no-repeat",
              backgroundSize: "cover",
              position: "relative",
            }}
          >
            <img
              src={data.image_url}
              className="img-fluid rounded-start"
              style={{
                height: "270px",
                width: "100%",
                objectFit: "contain",
                objectPosition: "center",
                backdropFilter: "saturate(180%) blur(20px)",
              }}
            />
            {patternVisible ? (
              <img
                src={data.pattern_image_url}
                style={{
                  height: `${patternSize}px`,
                  width: `${patternSize}px`,
                  position: "absolute",
                  bottom: "10px",
                  left: "10px",
                  imageRendering: "pixelated",
                  border: "1px solid white",
                  boxShadow: "0px 0px 6px 2px rgb(0 0 0 / 20%)",
                }}
              />
            ) : (
              <></>
            )}
          </div>
        </div>
        <div className="col-md-8">
          <div className="card-body">
            {data.title ? <h5 className="card-title">{data.title}</h5> : <></>}
            <p className="card-text">
              {data.artist_name} ({data.artist_birth_year} -{" "}
              {data.artist_death_year})
            </p>
            {data.percentage_similarity >= 0 && data.distance >= 0 ? (
              <p className="card-text">
                <small className="text-muted">
                  <span className="text-success">
                    Similitud: {data.percentage_similarity}%
                  </span>
                  <span className="text-danger mx-3">
                    Distancia: {parseFloat(data.distance).toFixed(2)}
                  </span>
                </small>
              </p>
            ) : (
              <></>
            )}
            {data.percentage_similarity != 0 ? (
              <button onClick={onClick} className="btn btn-outline-dark">
                Ver similares
              </button>
            ) : (
              <></>
            )}
            <div className="form-check mt-2">
              <input
                className="form-check-input"
                type="checkbox"
                checked={patternVisible}
                onChange={() => setPatternVisible(!patternVisible)}
                id={`checkbox-pattern-${data.id}`}
              />
              <label
                className="form-check-label"
                htmlFor={`checkbox-pattern-${data.id}`}
              >
                Ver patrón
              </label>
            </div>
            {patternVisible ? (
              <input
                type="range"
                className="form-range"
                min="32"
                max="120"
                value={patternSize}
                onChange={(e) => setPatternSize(e?.target?.value)}
              ></input>
            ) : (
              <></>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function Pivot({ data }) {
  return (
    <div className="card mb-3">
      <div className="row g-0">
        <div className="col-md-2">
          <img
            src={data.image_url}
            className="img-fluid rounded-start"
            style={{
              width: "100px",
              imageRendering: "pixelated",
            }}
          />
        </div>
        <div className="col-md-10">
          <div className="card-body">
            {data.level ? (
              <h5 className="card-title">Nivel: {data.level}</h5>
            ) : (
              <></>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function Navbar({ title, parts = [] }) {
  return (
    <nav
      className="navbar navbar-dark navbar-expand-lg py-2 mb-3"
      style={{
        backgroundColor: "rgba(0, 0, 0, .85)",
        backdropFilter: "saturate(180%) blur(20px)",
      }}
    >
      <div className="container">
        <a className="navbar-brand">{title}</a>
        <button
          className="navbar-toggler"
          type="button"
          data-bs-toggle="collapse"
          data-bs-target="#navbarCollapse"
          aria-controls="navbarCollapse"
          aria-expanded="false"
          aria-label="Toggle navigation"
        >
          <span className="navbar-toggler-icon"></span>
        </button>
        <div className="collapse navbar-collapse" id="navbarCollapse">
          {parts.map((part) => part)}
        </div>
      </div>
    </nav>
  );
}

function ArtworksPage() {
  const [items, setItems] = React.useState([]);

  const title = document.title;

  React.useEffect(() => {
    axios({
      method: "get",
      url: "/artworks/random",
    }).then((response) => {
      setItems(response.data);
    });
  }, []);

  return (
    <>
      <header className="sticky-top">
        <Navbar
          title={title}
          parts={[
            <ul key="links" className="navbar-nav me-auto mb-2 mb-lg-0">
              <li className="nav-item">
                <a
                  className="nav-link active"
                  aria-current="page"
                  href="pivots.html"
                >
                  Pivotes
                </a>
              </li>
            </ul>,
            <Form key="form" setItems={setItems} />,
          ]}
        />
      </header>
      <main>
        <div className="container">
          <div className="row row-cols-2">
            {items.map((data) => (
              <div key={`artwork-col-${data.id}`} className="col">
                <Artwork data={data} setItems={setItems} />
              </div>
            ))}
          </div>
        </div>
      </main>
    </>
  );
}

function PivotsPage() {
  const [items, setItems] = React.useState([]);

  const title = document.title;

  React.useEffect(() => {
    axios({
      method: "get",
      url: "/pivots",
    }).then((response) => {
      setItems(response.data);
    });
  }, []);

  return (
    <>
      <header className="sticky-top">
        <Navbar
          title={title}
          parts={[
            <ul key="links" className="navbar-nav me-auto mb-2 mb-lg-0">
              <li className="nav-item">
                <a
                  key="arworks-link"
                  className="nav-link active"
                  aria-current="page"
                  href="artworks.html"
                >
                  Obras de arte
                </a>
              </li>
            </ul>,
          ]}
        />
      </header>
      <main>
        <div className="container">
          <div className="row row-cols-2">
            {items.map((data) => (
              <div key={`pivot-col-${data.id}`} className="col">
                <Pivot data={data} />
              </div>
            ))}
          </div>
        </div>
      </main>
    </>
  );
}
