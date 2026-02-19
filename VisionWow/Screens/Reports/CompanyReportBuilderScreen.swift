//
//  CompanyReportBuilderScreen.swift
//  VisionWow
//
//  Created by Rodrigo Marcos on 19/02/26.
//

import SwiftUI
import SwiftData
import Charts

enum ReportOutputType: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case csv = "Excel (CSV)"
    var id: String { rawValue }
}

struct DiopterBucket: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let min: Double
    let max: Double
}

struct CompanyReportBuilderScreen: View {
    @Environment(\.modelContext) private var modelContext

    let companyId: UUID

    @Query(sort: \Company.createdAt, order: .reverse) private var companies: [Company]
    private var company: Company? { companies.first(where: { $0.id == companyId }) }

    // Output
    @State private var outputType: ReportOutputType = .pdf

    // Filtros
    @State private var dateFrom: Date? = nil
    @State private var dateTo: Date? = nil

    // Search
    @State private var antecedentSearch: String = ""

    // Antecedentes seleccionados (key -> Bool)
    @State private var antecedentFilters: [String: Bool] = [:]

    // Llaves por sección (para UI ordenada)
    @State private var antecedentKeys_antecedentes: [String] = []
    @State private var antecedentKeys_sintomas: [String] = []
    @State private var antecedentKeys_cirugias: [String] = []
    @State private var antecedentKeys_conjuntivitis: [String] = []
    @State private var antecedentKeys_computadora: [String] = []
    @State private var antecedentKeys_anexos: [String] = []
    @State private var antecedentKeys_salud: [String] = []
    @State private var antecedentKeys_saludOcular: [String] = []
    @State private var antecedentKeys_consultas: [String] = []

    // Qué incluir
    @State private var includeOverview = true
    @State private var includePaymentStats = true
    @State private var includeAntecedentStats = true
    @State private var includeDiopterStats = true
    @State private var includePatientList = false

    // Resultado / archivo
    @State private var generatedFileURL: URL? = nil
    @State private var showShare = false
    @State private var errorMessage: String? = nil
    @State private var isGenerating = false

    var body: some View {
        ZStack {
            BrandColors.backgroundGradient.ignoresSafeArea()

            if let company {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(company)

                        outputSection
                        filtersSection(company)
                        includeSection
                        previewSection(company)
                        generateSection(company)

                        Spacer(minLength: 18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .navigationTitle("Generar reporte")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    bootstrapAntecedentFilters()
                }
                .sheet(isPresented: $showShare) {
                    if let url = generatedFileURL {
                        ReportShareSheet(activityItems: [url])
                    }
                }
                .alert("Error", isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { _ in errorMessage = nil }
                )) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(errorMessage ?? "")
                }

            } else {
                Text("Empresa no encontrada.")
                    .font(.headline)
                    .padding(16)
            }
        }
    }

    // MARK: - Header

    private func header(_ company: Company) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(company.name)
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("Crea un reporte personalizado con filtros, métricas y gráficas.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(card)
    }

    // MARK: - Output

    private var outputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Formato de salida")
                .font(.headline)

            Picker("Salida", selection: $outputType) {
                ForEach(ReportOutputType.allCases) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(14)
        .background(card)
    }

    // MARK: - Filters

    private func filtersSection(_ company: Company) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Filtros")
                    .font(.headline)

                Spacer()

                let active = selectedAntecedentKeys.count
                Text(active == 0 ? "Sin filtros" : "\(active) activos")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(active == 0 ? .secondary : BrandColors.primary)
            }

            // Fechas
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Filtrar por rango de fechas", isOn: Binding(
                    get: { dateFrom != nil || dateTo != nil },
                    set: { enabled in
                        if !enabled { dateFrom = nil; dateTo = nil }
                        else {
                            dateFrom = Calendar.current.date(byAdding: .month, value: -1, to: Date())
                            dateTo = Date()
                        }
                    }
                ))

                if dateFrom != nil || dateTo != nil {
                    DatePicker("Desde", selection: Binding(
                        get: { dateFrom ?? Date() },
                        set: { dateFrom = $0 }
                    ), displayedComponents: .date)

                    DatePicker("Hasta", selection: Binding(
                        get: { dateTo ?? Date() },
                        set: { dateTo = $0 }
                    ), displayedComponents: .date)
                }
            }
            .padding(12)
            .background(subcard)

            // Buscador + acciones
            VStack(alignment: .leading, spacing: 10) {
                Text("Antecedentes / síntomas")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField("Buscar… (ej. Dolor de Cabeza, Vista cansada)", text: $antecedentSearch)
                    .textInputAutocapitalization(.sentences)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.90))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                            )
                    )

                HStack(spacing: 10) {
                    Button { clearAllAntecedentFilters() } label: {
                        Label("Limpiar todo", systemImage: "xmark.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button { selectAllVisibleAntecedents() } label: {
                        Label("Seleccionar visibles", systemImage: "checkmark.circle")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(BrandColors.primary)
                }
            }
            .padding(12)
            .background(subcard)

            // Secciones completas (siempre)
            VStack(spacing: 10) {
                antecedentDisclosureSection(title: "Antecedentes", keys: antecedentKeys_antecedentes)
                antecedentDisclosureSection(title: "Síntomas", keys: antecedentKeys_sintomas)
                antecedentDisclosureSection(title: "Cirugías", keys: antecedentKeys_cirugias)
                antecedentDisclosureSection(title: "Conjuntivitis", keys: antecedentKeys_conjuntivitis)
                antecedentDisclosureSection(title: "Computadora", keys: antecedentKeys_computadora)
                antecedentDisclosureSection(title: "Anexos", keys: antecedentKeys_anexos)
                antecedentDisclosureSection(title: "Salud", keys: antecedentKeys_salud)
                antecedentDisclosureSection(title: "Salud ocular", keys: antecedentKeys_saludOcular)
                antecedentDisclosureSection(title: "Consultas", keys: antecedentKeys_consultas)
            }
            .padding(12)
            .background(subcard)
        }
        .padding(14)
        .background(card)
    }

    // MARK: - Include

    private var includeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Contenido del reporte")
                .font(.headline)

            Toggle("Resumen general", isOn: $includeOverview)
            Toggle("Estadísticas de compra (lentes)", isOn: $includePaymentStats)
            Toggle("Estadísticas por antecedentes", isOn: $includeAntecedentStats)
            Toggle("Rangos de graduación (dioptrías)", isOn: $includeDiopterStats)
            Toggle("Listado de pacientes (detalle)", isOn: $includePatientList)

            Text("Tip: el listado detallado hace el PDF más largo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(card)
    }

    // MARK: - Preview

    private func previewSection(_ company: Company) -> some View {
        let encounters = filteredEncounters(company)
        let summary = ReportComputer.computeSummary(
            company: company,
            encounters: encounters,
            selectedAntecedentKeys: selectedAntecedentKeys
        )

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Vista previa")
                    .font(.headline)
                Spacer()
                Text("\(summary.totalEncounters) pacientes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                statTile("Pacientes", "\(summary.totalEncounters)")
                statTile("Compraron", "\(summary.boughtCount)")
                statTile("No compraron", "\(summary.notBoughtCount)")
            }

            if includeDiopterStats {
                Text("Rangos de graduación (esfera) — distribución")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Chart(summary.diopterDistribution) { item in
                    BarMark(
                        x: .value("Rango", item.label),
                        y: .value("Cantidad", item.count)
                    )
                }
                .frame(height: 190)
                .padding(.top, 4)
            }

            if includeAntecedentStats {

                // ✅ SIEMPRE muestra lo que marcaron los pacientes (Top global)
                let topGlobal = summary.topAntecedents.prefix(8)
                if !topGlobal.isEmpty {
                    Text("Top antecedentes (marcados por pacientes)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 8) {
                        ForEach(Array(topGlobal), id: \.0) { item in
                            HStack {
                                Text(item.0).lineLimit(1)
                                Spacer()
                                Text("\(item.1)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.top, 2)
                } else {
                    Text("Sin antecedentes capturados en los registros.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // ✅ Si hay filtros activos, añade conteo de esos filtros dentro de la muestra
                if !selectedAntecedentKeys.isEmpty {
                    let selectedCounts = summary.antecedentCountsSelectedFilterKeys
                        .sorted { $0.value > $1.value }
                        .prefix(8)

                    Text("Filtros seleccionados (conteo dentro de la muestra)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        ForEach(Array(selectedCounts), id: \.key) { key, value in
                            HStack {
                                Text(key).lineLimit(1)
                                Spacer()
                                Text("\(value)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(card)
    }

    // MARK: - Generate

    private func generateSection(_ company: Company) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generación")
                .font(.headline)

            Button { generate(company) } label: {
                HStack {
                    if isGenerating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "doc.badge.gearshape")
                    }
                    Text(isGenerating ? "Generando..." : "Generar documento")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(BrandColors.primary)
                )
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)

            if let url = generatedFileURL {
                Button { showShare = true } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir / Exportar")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(BrandColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.88))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(BrandColors.primary.opacity(0.20), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                Text(url.lastPathComponent)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .background(card)
    }

    // MARK: - UI helpers

    private func statTile(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.86))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(Color.white.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.16), lineWidth: 1)
            )
    }

    private var subcard: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.white.opacity(0.86))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(BrandColors.accent.opacity(0.14), lineWidth: 1)
            )
    }

    private func antecedentDisclosureSection(title: String, keys: [String]) -> some View {
        let q = antecedentSearch.trimmingCharacters(in: .whitespacesAndNewlines)

        // Mostrar todo si no hay búsqueda, si hay búsqueda filtra.
        let filtered = keys.filter { k in
            if q.isEmpty { return true }
            return k.localizedCaseInsensitiveContains(q)
        }

        let selectedCount = keys.filter { antecedentFilters[$0] == true }.count

        return DisclosureGroup {
            if filtered.isEmpty {
                Text("Sin resultados.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 6)
            } else {
                FlowWrap(filtered, spacing: 8) { key in
                    let selected = antecedentFilters[key] ?? false
                    Button {
                        antecedentFilters[key] = !selected
                    } label: {
                        Text(key)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(selected ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                    .fill(selected ? BrandColors.primary : Color.white.opacity(0.92))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 999, style: .continuous)
                                            .stroke(BrandColors.primary.opacity(0.18), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if selectedCount > 0 {
                    Text("\(selectedCount)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule(style: .continuous).fill(BrandColors.primary))
                } else {
                    Text("0")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BrandColors.accent.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Logic

    private var selectedAntecedentKeys: [String] {
        antecedentFilters.compactMap { $0.value ? $0.key : nil }
    }

    /// ✅ Siempre arma secciones completas.
    /// ✅ Si ya había filtros guardados, NO los pierde: fusiona llaves faltantes.
    private func bootstrapAntecedentFilters() {
        let a = Antecedents.defaults()

        // 1) Siempre recalcular listas por sección (esto arregla lo "mochado")
        antecedentKeys_antecedentes = Array(a.antecedentes.keys).sorted()
        antecedentKeys_sintomas = Array(a.sintomas.keys).sorted()
        antecedentKeys_cirugias = Array(a.cirugias.keys).sorted()
        antecedentKeys_conjuntivitis = Array(a.conjuntivitis.keys).sorted()
        antecedentKeys_computadora = Array(a.computadora.keys).sorted()
        antecedentKeys_anexos = Array(a.anexos.keys).sorted()
        antecedentKeys_salud = Array(a.salud.keys).sorted()
        antecedentKeys_saludOcular = Array(a.saludOcular.keys).sorted()
        antecedentKeys_consultas = Array(a.consultas.keys).sorted()

        // 2) Construir set total de llaves
        var allKeys: [String] = []
        allKeys += antecedentKeys_antecedentes
        allKeys += antecedentKeys_sintomas
        allKeys += antecedentKeys_cirugias
        allKeys += antecedentKeys_conjuntivitis
        allKeys += antecedentKeys_computadora
        allKeys += antecedentKeys_anexos
        allKeys += antecedentKeys_salud
        allKeys += antecedentKeys_saludOcular
        allKeys += antecedentKeys_consultas

        let uniqueAll = Array(Set(allKeys)).sorted()

        // 3) Fusionar al diccionario existente (sin borrar selección previa)
        if antecedentFilters.isEmpty {
            var dict: [String: Bool] = [:]
            uniqueAll.forEach { dict[$0] = false }
            antecedentFilters = dict
        } else {
            var dict = antecedentFilters
            uniqueAll.forEach { key in
                if dict[key] == nil { dict[key] = false }
            }
            // opcional: si quieres eliminar llaves viejas que ya no existen en defaults
            // dict = dict.filter { uniqueAll.contains($0.key) }
            antecedentFilters = dict
        }
    }

    private func clearAllAntecedentFilters() {
        for k in antecedentFilters.keys {
            antecedentFilters[k] = false
        }
    }

    private func selectAllVisibleAntecedents() {
        let q = antecedentSearch.trimmingCharacters(in: .whitespacesAndNewlines)

        for k in antecedentFilters.keys {
            if q.isEmpty || k.localizedCaseInsensitiveContains(q) {
                antecedentFilters[k] = true
            }
        }
    }

    private func filteredEncounters(_ company: Company) -> [Encounter] {
        var list = company.encounters

        // Fecha
        if let from = dateFrom {
            list = list.filter { $0.createdAt >= from }
        }
        if let to = dateTo {
            let end = Calendar.current.date(byAdding: .day, value: 1, to: to) ?? to
            list = list.filter { $0.createdAt < end }
        }

        // Antecedentes (modo OR para no quedarte en 0 muy fácil)
        let keys = selectedAntecedentKeys
        if !keys.isEmpty {
            list = list.filter { enc in
                guard let ant = AntecedentsCodec.decode(from: enc.antecedentesJSON) else { return false }
                return keys.contains(where: { AntecedentsCodec.hasKeyEnabled(ant, key: $0) })
            }
        }

        return list
    }

    private func generate(_ company: Company) {
        isGenerating = true
        generatedFileURL = nil

        let encounters = filteredEncounters(company)
        let summary = ReportComputer.computeSummary(
            company: company,
            encounters: encounters,
            selectedAntecedentKeys: selectedAntecedentKeys
        )

        do {
            switch outputType {
            case .pdf:
                let url = try ReportGenerator.generatePDF(
                    company: company,
                    encounters: encounters,
                    summary: summary,
                    includeOverview: includeOverview,
                    includePaymentStats: includePaymentStats,
                    includeAntecedentStats: includeAntecedentStats,
                    includeDiopterStats: includeDiopterStats,
                    includePatientList: includePatientList,
                    selectedAntecedentKeys: selectedAntecedentKeys
                )
                generatedFileURL = url

            case .csv:
                let url = try ReportGenerator.generateCSV(
                    company: company,
                    encounters: encounters
                )
                generatedFileURL = url
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isGenerating = false
    }
}
